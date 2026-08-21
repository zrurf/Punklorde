package main

/*
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#ifdef __ANDROID__
#include <android/log.h>
static void go_logi(const char* msg) {
    __android_log_print(ANDROID_LOG_INFO, "go_tunnel", "%s", msg);
}
static void go_loge(const char* msg) {
    __android_log_print(ANDROID_LOG_ERROR, "go_tunnel", "%s", msg);
}
#else
static void go_logi(const char* msg) { (void)msg; }
static void go_loge(const char* msg) { (void)msg; }
#endif
*/
import "C"
import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"encoding/hex"
	"encoding/xml"
	"errors"
	"io"
	"math/big"
	"net"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
	"unsafe"

	utls "github.com/refraction-networking/utls"
)

// ===================== Types =====================

// VpnClient 代表一个VPN客户端实例
type VpnClient struct {
	id         int
	server     string // host:port
	username   string
	password   string
	totpSecret string
	smsCode    string

	twfID string
	token [48]byte
	ip    net.IP
	ipRev []byte

	httpClient   *http.Client
	sendConn     *utls.UConn
	recvConn     *utls.UConn
	sendLock     sync.Mutex
	recvLock     sync.Mutex
	reconnectMu  sync.Mutex
	sendErrCount int
	recvErrCount int

	// lifecycle: cancel() stops background keepalive goroutines
	stopCtx       context.Context
	stopCancel    context.CancelFunc
	keepAliveOnce sync.Once

	resources string // raw XML
	dnsServer string
	dnsData   map[string]string // domain -> IP from <Dns data="...">
	routes    string            // comma-separated CIDRs from resource IP ranges
	connected bool
	mu        sync.Mutex
}

// ===================== Globals =====================

var (
	clients    = make(map[int]*VpnClient)
	nextID     = 1
	globalMu   sync.Mutex
	writeCount uint64
	readCount  uint64
	readMu     sync.Mutex
	writeMu    sync.Mutex
)

// ===================== C Exports =====================

// normalizeServer strips protocol prefixes and ensures a port is present.
// Default port 443 is appended if no port is specified.
func normalizeServer(server string) string {
	// Strip protocol prefixes
	server = strings.TrimPrefix(server, "https://")
	server = strings.TrimPrefix(server, "http://")

	// Add default port 443 if no port specified
	if !strings.Contains(server, ":") {
		server = server + ":443"
	}
	return server
}

//export EC_New
func EC_New(server, username, password, totpSecret *C.char) C.int {
	globalMu.Lock()
	defer globalMu.Unlock()
	id := nextID
	nextID++

	rawServer := C.GoString(server)
	normalized := normalizeServer(rawServer)

	stopCtx, stopCancel := context.WithCancel(context.Background())

	c := &VpnClient{
		id:         id,
		server:     normalized,
		username:   C.GoString(username),
		password:   C.GoString(password),
		totpSecret: C.GoString(totpSecret),
		stopCtx:    stopCtx,
		stopCancel: stopCancel,
		httpClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			},
		},
	}
	clients[id] = c
	return C.int(id)
}

//export EC_SetSmsCode
func EC_SetSmsCode(id C.int, code *C.char) {
	c := getClient(int(id))
	if c != nil {
		c.smsCode = C.GoString(code)
	}
}

//export EC_Free
func EC_Free(id C.int) {
	globalMu.Lock()
	defer globalMu.Unlock()
	if c, ok := clients[int(id)]; ok {
		c.close()
		delete(clients, int(id))
	}
}

//export EC_LoginStart
func EC_LoginStart(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	twfID, err := c.loginStart()
	if err != nil {
		return errStr(err.Error())
	}
	c.twfID = twfID
	return nil
}

//export EC_LoginPassword
func EC_LoginPassword(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.loginPassword()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

//export EC_LoginSMS
func EC_LoginSMS(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.loginSMS()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

//export EC_LoginTOTP
func EC_LoginTOTP(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.loginTOTP()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

//export EC_GetToken
func EC_GetToken(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.getToken()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

//export EC_GetResources
func EC_GetResources(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	xmlData, err := c.getResources()
	if err != nil {
		return errStr(err.Error())
	}
	return C.CString(xmlData)
}

//export EC_GetIP
func EC_GetIP(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.getIP()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

//export EC_GetAssignedIP
func EC_GetAssignedIP(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil || c.ip == nil || len(c.ip) < 4 {
		return C.CString("")
	}
	return C.CString(net.IPv4(c.ip[0], c.ip[1], c.ip[2], c.ip[3]).String())
}

//export EC_OpenDataChannels
func EC_OpenDataChannels(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return errStr("client not found")
	}
	err := c.openDataChannels()
	if err != nil {
		return errStr(err.Error())
	}
	return nil
}

func isFatalReadError(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return errors.Is(err, io.EOF) ||
		errors.Is(err, io.ErrClosedPipe) ||
		errors.Is(err, net.ErrClosed) ||
		strings.Contains(errStr, "connection abort") ||
		strings.Contains(errStr, "connection reset") ||
		strings.Contains(errStr, "broken pipe") ||
		strings.Contains(errStr, "use of closed network connection")
}

//export EC_ReadRecv
func EC_ReadRecv(id C.int, buf unsafe.Pointer, bufLen C.int) C.int {
	c := getClient(int(id))
	if c == nil || c.recvConn == nil {
		return -1
	}

	readMu.Lock()
	readCount++
	rc := readCount
	readMu.Unlock()

	if rc == 1 {
		C.go_logi(C.CString("EC_ReadRecv #1: entering blocking read on recvConn..."))
	}

	data := make([]byte, bufLen)
	c.recvLock.Lock()
	n, err := c.recvConn.Read(data)
	c.recvLock.Unlock()

	for err != nil && c.recvErrCount < 5 {
		if rc <= 5 || rc%50 == 0 {
			C.go_loge(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " error (retry " + strconv.Itoa(c.recvErrCount+1) + "/5): " + err.Error()))
		}
		if reconnErr := c.reconnectDataChannels(); reconnErr != nil {
			C.go_loge(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " reconnectDataChannels failed: " + reconnErr.Error()))
			c.recvErrCount++
			if c.recvErrCount >= 5 {
				return -1
			}
			continue
		}
		c.recvErrCount = 0
		c.recvLock.Lock()
		n, err = c.recvConn.Read(data)
		c.recvLock.Unlock()
		if err == nil {
			C.go_logi(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " reconnected and received " + strconv.Itoa(n) + " bytes"))
			break
		}
		c.recvErrCount++
	}
	if c.recvErrCount >= 5 {
		C.go_loge(C.CString("EC_ReadRecv: all retries exhausted"))
		return -1
	}

	if err != nil {
		if rc <= 5 || rc%50 == 0 {
			C.go_loge(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " error: " + err.Error() + " n=" + strconv.Itoa(n)))
		}
		if n > 0 {
			C.memcpy(buf, unsafe.Pointer(&data[0]), C.size_t(n))
			if rc <= 3 {
				hexPart := hex.EncodeToString(data[:min(n, 80)])
				C.go_logi(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " received " + strconv.Itoa(n) + " bytes (with error) hex=" + hexPart))
			}
			return C.int(n)
		}
		if isFatalReadError(err) {
			C.go_loge(C.CString("EC_ReadRecv: fatal read error, connection is dead"))
			return -1
		}
		return C.int(n)
	}
	if n > 0 {
		C.memcpy(buf, unsafe.Pointer(&data[0]), C.size_t(n))
		if rc <= 5 {
			hexPart := hex.EncodeToString(data[:min(n, 80)])
			C.go_logi(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " received " + strconv.Itoa(n) + " bytes hex=" + hexPart))
		}
		return C.int(n)
	}
	if rc <= 5 {
		C.go_logi(C.CString("EC_ReadRecv #" + strconv.FormatUint(rc, 10) + " returned 0 bytes (no error)"))
	}
	return 0
}

//export EC_WriteSend
func EC_WriteSend(id C.int, buf unsafe.Pointer, bufLen C.int) C.int {
	c := getClient(int(id))
	if c == nil || c.sendConn == nil {
		return -1
	}
	data := C.GoBytes(buf, bufLen)

	writeMu.Lock()
	writeCount++
	wc := writeCount
	writeMu.Unlock()

	c.sendLock.Lock()
	n, err := c.sendConn.Write(data)
	c.sendLock.Unlock()

	for err != nil && c.sendErrCount < 5 {
		C.go_loge(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " error (retry " + strconv.Itoa(c.sendErrCount+1) + "/5): " + err.Error()))
		if reconnErr := c.reconnectDataChannels(); reconnErr != nil {
			C.go_loge(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " reconnectDataChannels failed: " + reconnErr.Error()))
			c.sendErrCount++
			if c.sendErrCount >= 5 {
				return -1
			}
			continue
		}
		c.sendErrCount = 0
		c.sendLock.Lock()
		n, err = c.sendConn.Write(data)
		c.sendLock.Unlock()
		if err == nil {
			C.go_logi(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " reconnected and wrote " + strconv.Itoa(n) + " bytes"))
			break
		}
		c.sendErrCount++
	}
	if c.sendErrCount >= 5 {
		C.go_loge(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " all retries exhausted"))
		return -1
	}

	if err != nil {
		C.go_loge(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " error: " + err.Error()))
		if n > 0 {
			C.go_loge(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " partial write " + strconv.Itoa(n) + " bytes with error"))
		}
		return -1
	}
	if wc <= 5 {
		hexPart := hex.EncodeToString(data[:min(int(bufLen), 80)])
		C.go_logi(C.CString("EC_WriteSend #" + strconv.FormatUint(wc, 10) + " wrote " + strconv.Itoa(n) + " bytes hex=" + hexPart))
	}
	return C.int(n)
}

//export EC_ReadSend
func EC_ReadSend(id C.int, buf unsafe.Pointer, bufLen C.int) C.int {
	c := getClient(int(id))
	if c == nil || c.sendConn == nil {
		return -1
	}
	data := make([]byte, bufLen)
	c.sendLock.Lock()
	n, err := c.sendConn.Read(data)
	c.sendLock.Unlock()

	if err != nil {
		if n > 0 {
			C.memcpy(buf, unsafe.Pointer(&data[0]), C.size_t(n))
		}
		return C.int(n)
	}
	if n > 0 {
		C.memcpy(buf, unsafe.Pointer(&data[0]), C.size_t(n))
	}
	return C.int(n)
}

//export EC_GetDNSServer
func EC_GetDNSServer(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil || c.dnsServer == "" {
		return C.CString("")
	}
	return C.CString(c.dnsServer)
}

//export EC_IsConnected
func EC_IsConnected(id C.int) C.int {
	c := getClient(int(id))
	if c == nil {
		return 0
	}
	if c.connected {
		return 1
	}
	return 0
}

//export EC_GetDnsData
func EC_GetDnsData(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil || len(c.dnsData) == 0 {
		return C.CString("")
	}
	parts := make([]string, 0, len(c.dnsData))
	for domain, ip := range c.dnsData {
		parts = append(parts, domain+"="+ip)
	}
	return C.CString(strings.Join(parts, ";"))
}

//export EC_GetDnsRoutes
func EC_GetDnsRoutes(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil || len(c.dnsData) == 0 {
		return C.CString("")
	}
	seen := make(map[string]bool)
	ips := make([]string, 0, len(c.dnsData))
	for _, ip := range c.dnsData {
		if !seen[ip] {
			seen[ip] = true
			ips = append(ips, ip)
		}
	}
	return C.CString(strings.Join(ips, ","))
}

//export EC_GetRoutes
func EC_GetRoutes(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil || c.routes == "" {
		return C.CString("")
	}
	return C.CString(c.routes)
}

// ===================== Helpers =====================

func getClient(id int) *VpnClient {
	globalMu.Lock()
	defer globalMu.Unlock()
	return clients[id]
}

func errStr(msg string) *C.char {
	return C.CString("ERR:" + msg)
}

// ===================== Client Methods =====================

func (c *VpnClient) close() {
	if c.stopCancel != nil {
		c.stopCancel()
	}
	if c.sendConn != nil {
		c.sendConn.Close()
	}
	if c.recvConn != nil {
		c.recvConn.Close()
	}
}

// errNotFound is returned by requestUpdateSession when the server does not
// implement /por/update_session.csp (HTTP 404), in which case the periodic
// session keepalive should be stopped.
var errNotFound = errors.New("not found")

// sessionKeepAliveLoop periodically calls /por/update_session.csp to keep the
// server-side session alive (mirrors the official EasyConnect client and the
// reference zju-connect). Without it, sangfor servers with strict idle
// policies close the session, which the tunnel layer surfaces as a broken
// pipe / dropped connection.
//
// The loop stops when the client is closed (EC_Free) or when the server
// reports it does not support update_session.
func (c *VpnClient) sessionKeepAliveLoop() {
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-c.stopCtx.Done():
			return
		case <-ticker.C:
			ctx, cancel := context.WithTimeout(c.stopCtx, 10*time.Second)
			err := c.requestUpdateSession(ctx)
			cancel()
			if err == nil {
				continue
			}
			if errors.Is(err, errNotFound) {
				C.go_loge(C.CString("session keepalive: server does not support update_session, stopping"))
				return
			}
			C.go_loge(C.CString("session keepalive: update_session failed: " + err.Error()))
		}
	}
}

// requestUpdateSession pings /por/update_session.csp to keep the server-side
// session alive.
func (c *VpnClient) requestUpdateSession(ctx context.Context) error {
	u := url.URL{
		Scheme: "https",
		Host:   c.server,
		Path:   "/por/update_session.csp",
	}
	q := url.Values{}
	q.Set("twfid", c.twfID)
	q.Set("apiversion", "1")
	u.RawQuery = q.Encode()

	req, err := http.NewRequestWithContext(ctx, "GET", u.String(), nil)
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_Linux_Ubuntu")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		if resp.StatusCode == http.StatusNotFound {
			return errNotFound
		}
		return errors.New("update_session: unexpected status " + strconv.Itoa(resp.StatusCode))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	// Successful body looks like:
	//   <Auth><Message>success</Message><ErrorCode>1</ErrorCode><TwfID>...</TwfID></Auth>
	var reply struct {
		Message   string `xml:"Message"`
		ErrorCode string `xml:"ErrorCode"`
	}
	if err := xml.Unmarshal(body, &reply); err != nil {
		return errors.New("update_session: parse reply: " + err.Error())
	}
	if reply.Message != "success" || reply.ErrorCode != "1" {
		return errors.New("update_session: unexpected reply message='" + reply.Message + "' error_code='" + reply.ErrorCode + "'")
	}
	return nil
}

type fakeHeartBeatExtension struct {
	*utls.GenericExtension
}

func (e *fakeHeartBeatExtension) Len() int {
	return 5
}

func (e *fakeHeartBeatExtension) Read(b []byte) (n int, err error) {
	if len(b) < e.Len() {
		return 0, io.ErrShortBuffer
	}
	b[1] = 0x0f
	b[3] = 1
	b[4] = 1
	return e.Len(), io.EOF
}

// tlsConn creates a special TLS connection for data channels.
// Sangfor routes everything on the shared 443 port by the SessionId in
// the TLS ClientHello: the fixed "L3IP\0..." SessionId marks this as an
// L3 tunnel connection (VPN) as opposed to an HTTP/ECAgent connection.
// Using any other SessionId (e.g. the one echoed by the server in the
// getIP handshake) makes the server mishandle the connection, so it must
// stay constant — this matches the reference zju-connect implementation.
func (c *VpnClient) tlsConn() (*utls.UConn, error) {
	tcpAddr, err := net.ResolveTCPAddr("tcp", c.server)
	if err != nil {
		return nil, err
	}
	tcpConn, err := net.DialTCP("tcp", nil, tcpAddr)
	if err != nil {
		return nil, err
	}
	tcpConn.SetKeepAlive(true)
	tcpConn.SetKeepAlivePeriod(5 * time.Second)

	conn := utls.UClient(tcpConn, &utls.Config{InsecureSkipVerify: true}, utls.HelloCustom)
	random := make([]byte, 32)
	_, _ = rand.Read(random)
	_ = conn.SetClientRandom(random)
	_ = conn.SetTLSVers(tls.VersionTLS11, tls.VersionTLS11, []utls.TLSExtension{})
	conn.HandshakeState.Hello.Vers = tls.VersionTLS11
	conn.HandshakeState.Hello.CipherSuites = []uint16{
		tls.TLS_RSA_WITH_RC4_128_SHA,
		0x00FF,
	}
	conn.HandshakeState.Hello.CompressionMethods = []uint8{1, 0}
	conn.HandshakeState.Hello.SessionId = []byte{'L', '3', 'I', 'P', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	conn.Extensions = []utls.TLSExtension{&fakeHeartBeatExtension{}}
	return conn, nil
}

// extractXmlText extracts CDATA text from an XML element.
// e.g., <Message><![CDATA[Invalid username or password!]]></Message> -> "Invalid username or password!"
func extractXmlText(xmlStr string, tag string) string {
	re := regexp.MustCompile(`<` + tag + `><!\[CDATA\[(.*?)\]\]></` + tag + `>`)
	m := re.FindStringSubmatch(xmlStr)
	if m != nil {
		return m[1]
	}
	// Try without CDATA
	re2 := regexp.MustCompile(`<` + tag + `>(.*?)</` + tag + `>`)
	m2 := re2.FindStringSubmatch(xmlStr)
	if m2 != nil {
		return m2[1]
	}
	return ""
}

// ========== Login Flow ==========

func (c *VpnClient) loginStart() (string, error) {
	addr := "https://" + c.server + "/por/login_auth.csp?apiversion=1"
	resp, err := c.httpClient.Get(addr)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return "", err
	}
	body := buf.String()

	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(body)
	if twfMatch == nil {
		return "", errors.New("no TwfID in response")
	}
	return twfMatch[1], nil
}

func (c *VpnClient) loginPassword() error {
	addr := "https://" + c.server + "/por/login_auth.csp?apiversion=1"
	req, err := http.NewRequest("GET", addr, nil)
	if err != nil {
		return err
	}
	// Must include TWFID cookie to get the correct CSRF code for the session
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return err
	}
	body := buf.Bytes()

	// Extract RSA key and CSRF
	rsaKey := string(regexp.MustCompile(`<RSA_ENCRYPT_KEY>(.*)</RSA_ENCRYPT_KEY>`).FindSubmatch(body)[1])
	rsaExpMatch := regexp.MustCompile(`<RSA_ENCRYPT_EXP>(.*)</RSA_ENCRYPT_EXP>`).FindSubmatch(body)
	rsaExp := "65537"
	if rsaExpMatch != nil {
		rsaExp = string(rsaExpMatch[1])
	}
	csrfMatch := regexp.MustCompile(`<CSRF_RAND_CODE>(.*)</CSRF_RAND_CODE>`).FindSubmatch(body)
	password := c.password
	csrfCode := ""
	if csrfMatch != nil {
		csrfCode = string(csrfMatch[1])
		password += "_" + csrfCode
	}

	// RSA encrypt password
	pubKey := rsa.PublicKey{}
	pubKey.E, _ = strconv.Atoi(rsaExp)
	modulus := big.Int{}
	modulus.SetString(rsaKey, 16)
	pubKey.N = &modulus
	encryptedPassword, err := rsa.EncryptPKCS1v15(rand.Reader, &pubKey, []byte(password))
	if err != nil {
		return err
	}
	encryptedPasswordHex := hex.EncodeToString(encryptedPassword)

	// Submit login
	addr = "https://" + c.server + "/por/login_psw.csp?anti_replay=1&encrypt=1&type=cs"
	form := url.Values{
		"svpn_rand_code":    {""},
		"mitm":              {""},
		"svpn_req_randcode": {csrfCode},
		"svpn_name":         {c.username},
		"svpn_password":     {encryptedPasswordHex},
	}
	req, err = http.NewRequest("POST", addr, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err = c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	buf.Reset()
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return err
	}
	respBody := buf.String()

	// Check for 2FA
	if strings.Contains(respBody, "<NextService>auth/sms</NextService>") || strings.Contains(respBody, "<NextAuth>2</NextAuth>") {
		return errors.New("SMS_REQUIRED")
	}
	if strings.Contains(respBody, "<NextService>auth/token</NextService>") || strings.Contains(respBody, "<NextAuth>7</NextAuth>") {
		return errors.New("TOTP_REQUIRED")
	}

	if !strings.Contains(respBody, "<Result>1</Result>") {
		// Extract human-readable error from server's XML response
		errMsg := extractXmlText(respBody, "Message")
		if errMsg == "" {
			errMsg = extractXmlText(respBody, "ErrorMsg")
		}
		if errMsg == "" {
			errMsg = extractXmlText(respBody, "Note")
		}
		if errMsg == "" {
			errMsg = respBody
		}
		return errors.New(errMsg)
	}

	// Update TWFID
	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(respBody)
	if twfMatch != nil {
		c.twfID = twfMatch[1]
	}
	return nil
}

func (c *VpnClient) loginSMS() error {
	// Request SMS
	addr := "https://" + c.server + "/por/login_sms.csp?apiversion=1"
	req, err := http.NewRequest("POST", addr, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if c.smsCode == "" {
		return errors.New("SMS code required, please call EC_SetSmsCode first")
	}

	// Submit SMS code
	addr = "https://" + c.server + "/por/login_sms1.csp?apiversion=1"
	form := url.Values{"svpn_inputsms": {c.smsCode}}
	req, err = http.NewRequest("POST", addr, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err = c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	io.Copy(&buf, resp.Body)
	respBody := buf.String()

	if !strings.Contains(respBody, "Auth sms suc") && !strings.Contains(respBody, "欢迎访问") {
		return errors.New("SMS verification failed: " + respBody)
	}

	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(respBody)
	if twfMatch != nil {
		c.twfID = twfMatch[1]
	}
	return nil
}

func (c *VpnClient) loginTOTP() error {
	if c.smsCode == "" {
		return errors.New("TOTP code required, please call EC_SetSmsCode first")
	}

	addr := "https://" + c.server + "/por/login_token.csp"
	form := url.Values{"svpn_inputtoken": {c.smsCode}}
	req, err := http.NewRequest("POST", addr, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	io.Copy(&buf, resp.Body)
	respBody := buf.String()

	if !strings.Contains(respBody, "Totp auth succ") {
		return errors.New("TOTP verification failed: " + respBody)
	}

	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(respBody)
	if twfMatch != nil {
		c.twfID = twfMatch[1]
	}
	return nil
}

// ========== Token ==========

func (c *VpnClient) getToken() error {
	dialConn, err := net.Dial("tcp", c.server)
	if err != nil {
		return err
	}
	defer dialConn.Close()

	conn := utls.UClient(dialConn, &utls.Config{InsecureSkipVerify: true}, utls.HelloGolang)
	defer conn.Close()

	// Send merged request to extract SessionId from TLS handshake
	_, err = io.WriteString(conn,
		"GET /por/conf.csp HTTP/1.1\r\nHost: "+c.server+
			"\r\nCookie: TWFID="+c.twfID+
			"\r\n\r\nGET /por/rclist.csp HTTP/1.1\r\nHost: "+c.server+
			"\r\nCookie: TWFID="+c.twfID+"\r\n\r\n",
	)
	if err != nil {
		return err
	}

	sessionID := hex.EncodeToString(conn.HandshakeState.ServerHello.SessionId)

	// Read response (discard)
	buf := make([]byte, 8)
	n, err := conn.Read(buf)
	if n == 0 || err != nil {
		return errors.New("token request invalid")
	}

	// Build token: hex SessionId (first 31 chars) + \x00 + TwfID (total 48 bytes)
	tokenBytes := []byte(sessionID[:31] + "\x00" + c.twfID)
	copy(c.token[:], tokenBytes[:48])

	C.go_logi(C.CString("getToken: token hex=" + hex.EncodeToString(c.token[:])))

	return nil
}

// ========== Resources ==========

func (c *VpnClient) getResources() (string, error) {
	addr := "https://" + c.server + "/por/rclist.csp"
	req, err := http.NewRequest("GET", addr, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	io.Copy(&buf, resp.Body)
	c.resources = buf.String()
	c.parseDNS()
	c.parseRoutes()
	routeCount := 0
	if c.routes != "" {
		routeCount = len(strings.Split(c.routes, ","))
	}
	C.go_logi(C.CString("getResources: parsed DNS=" + c.dnsServer + " routeCount=" + strconv.Itoa(routeCount)))
	return c.resources, nil
}

// parseDNS extracts DNS server info from resources XML
func (c *VpnClient) parseDNS() {
	// Log the FULL resources XML to understand where DNS info lives
	totalLen := len(c.resources)
	C.go_logi(C.CString("parseDNS: resources XML total length = " + strconv.Itoa(totalLen)))
	// Print in chunks of 500 chars
	for i := 0; i < totalLen; i += 500 {
		end := i + 500
		if end > totalLen {
			end = totalLen
		}
		C.go_logi(C.CString("parseDNS: chunk[" + strconv.Itoa(i/500) + "] = " + c.resources[i:end]))
	}

	// Try regex: dnsserver attribute (case insensitive)
	re := regexp.MustCompile(`(?i)dnsserver\s*=\s*"([^"]*)"`)
	m := re.FindStringSubmatch(c.resources)
	if m != nil && m[1] != "" && m[1] != "0.0.0.0" {
		c.dnsServer = strings.Split(m[1], ";")[0]
		C.go_logi(C.CString("parseDNS: regex dnsserver=\"" + m[1] + "\" -> " + c.dnsServer))
		return
	}
	if m != nil {
		C.go_logi(C.CString("parseDNS: regex dnsserver=\"" + m[1] + "\" (empty or 0.0.0.0, will try other methods)"))
	}

	// Try regex: <DnsServer> tag (case insensitive)
	re2 := regexp.MustCompile(`(?i)<DnsServer[^>]*>([^<]+)</DnsServer>`)
	m2 := re2.FindStringSubmatch(c.resources)
	if m2 != nil {
		c.dnsServer = strings.TrimSpace(m2[1])
		if c.dnsServer != "" && c.dnsServer != "0.0.0.0" {
			C.go_logi(C.CString("parseDNS: DnsServer tag = " + c.dnsServer))
			return
		}
	}

	// Try regex: <DomainServer> tag
	re3 := regexp.MustCompile(`(?i)<DomainServer[^>]*>([^<]+)</DomainServer>`)
	m3 := re3.FindStringSubmatch(c.resources)
	if m3 != nil {
		c.dnsServer = strings.TrimSpace(m3[1])
		if c.dnsServer != "" && c.dnsServer != "0.0.0.0" {
			C.go_logi(C.CString("parseDNS: DomainServer tag = " + c.dnsServer))
			return
		}
	}

	// Try regex: <dns> tag (lowercase)
	re4 := regexp.MustCompile(`(?i)<dns[^>]*>([^<]+)</dns>`)
	m4 := re4.FindStringSubmatch(c.resources)
	if m4 != nil {
		c.dnsServer = strings.TrimSpace(m4[1])
		if c.dnsServer != "" && c.dnsServer != "0.0.0.0" {
			C.go_logi(C.CString("parseDNS: <dns> tag = " + c.dnsServer))
			return
		}
	}

	// Try regex: any attribute containing "dns" with an IP value
	re5 := regexp.MustCompile(`(?i)(?:dns|nameserver|name_server)\w*\s*=\s*"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"`)
	m5 := re5.FindStringSubmatch(c.resources)
	if m5 != nil {
		c.dnsServer = m5[1]
		C.go_logi(C.CString("parseDNS: dns-like attribute with IP = " + c.dnsServer))
		return
	}

	// Try struct unmarshalling for <Dns>
	type DnsXml struct {
		XMLName   xml.Name `xml:"Dns"`
		Data      string   `xml:"data,attr"`
		DnsServer string   `xml:"dnsserver,attr"`
	}
	type ResourceXml struct {
		Dns DnsXml `xml:"Dns"`
	}

	var res ResourceXml
	if err := xml.Unmarshal([]byte(c.resources), &res); err != nil {
		C.go_loge(C.CString("parseDNS: xml.Unmarshal err = " + err.Error()))
		return
	}
	c.dnsServer = strings.Split(res.Dns.DnsServer, ";")[0]
	if c.dnsServer == "0.0.0.0" {
		c.dnsServer = ""
	}
	C.go_logi(C.CString("parseDNS: struct Dns.dnsserver = \"" + c.dnsServer + "\" Dns.data len = " + strconv.Itoa(len(res.Dns.Data))))

	// Parse Dns data into domain->IP map regardless of dnsserver
	// Format: "id:domain:ip;id:domain:ip;..."  e.g. "31:i.cqupt.edu.cn:202.202.32.62;..."
	if res.Dns.Data != "" {
		c.dnsData = make(map[string]string)
		entries := strings.Split(res.Dns.Data, ";")
		for _, entry := range entries {
			parts := strings.SplitN(entry, ":", 3)
			if len(parts) == 3 {
				domain := parts[1]
				ip := parts[2]
				// Skip numeric-only entries (IP-as-domain, no DNS needed)
				if net.ParseIP(domain) == nil && domain != "" && ip != "" {
					c.dnsData[domain] = ip
				}
			}
		}
		C.go_logi(C.CString("parseDNS: parsed " + strconv.Itoa(len(c.dnsData)) + " domain->IP mappings from data"))
	}

	if c.dnsServer == "" {
		C.go_logi(C.CString("parseDNS: no dnsserver, will use TUN-local DNS resolver with " + strconv.Itoa(len(c.dnsData)) + " mappings"))
	}
}

// parseRoutes extracts L3VPN IP ranges from resources XML and converts to CIDRs.
func (c *VpnClient) parseRoutes() {
	type RcXml struct {
		Host string `xml:"host,attr"`
		Type string `xml:"type,attr"`
	}
	type RcsXml struct {
		Rc []RcXml `xml:"Rc"`
	}
	type ResXml struct {
		Rcs RcsXml `xml:"Rcs"`
	}

	var res ResXml
	if err := xml.Unmarshal([]byte(c.resources), &res); err != nil {
		C.go_loge(C.CString("parseRoutes: xml.Unmarshal err = " + err.Error()))
		return
	}

	var allCIDRs []string
	seen := make(map[string]bool)

	for _, rc := range res.Rcs.Rc {
		if rc.Type != "2" {
			continue
		}
		hosts := strings.Split(rc.Host, ";")
		for _, host := range hosts {
			host = strings.TrimSpace(host)
			if host == "" || strings.HasPrefix(host, "http://") || strings.HasPrefix(host, "https://") {
				continue
			}

			if strings.Contains(host, "~") {
				parts := strings.SplitN(host, "~", 2)
				if len(parts) == 2 {
					start := net.ParseIP(strings.TrimSpace(parts[0]))
					end := net.ParseIP(strings.TrimSpace(parts[1]))
					if start != nil && end != nil && start.To4() != nil && end.To4() != nil {
						for _, cidr := range rangeToCIDRs(start.To4(), end.To4()) {
							if !seen[cidr] {
								seen[cidr] = true
								allCIDRs = append(allCIDRs, cidr)
							}
						}
					}
				}
			} else if ip := net.ParseIP(host); ip != nil && ip.To4() != nil {
				cidr := ip.String() + "/32"
				if !seen[cidr] {
					seen[cidr] = true
					allCIDRs = append(allCIDRs, cidr)
				}
			}
		}
	}

	// Always include TUN subnet so 10.255.255.1 DNS works
	tunCIDR := "10.0.0.0/8"
	if !seen[tunCIDR] {
		seen[tunCIDR] = true
		allCIDRs = append(allCIDRs, tunCIDR)
	}

	c.routes = strings.Join(allCIDRs, ",")
	C.go_logi(C.CString("parseRoutes: " + strconv.Itoa(len(allCIDRs)) + " CIDRs parsed"))
}

func ipToUint32(ip net.IP) uint32 {
	ip = ip.To4()
	return uint32(ip[0])<<24 | uint32(ip[1])<<16 | uint32(ip[2])<<8 | uint32(ip[3])
}

func uint32ToIP(n uint32) net.IP {
	return net.IPv4(byte(n>>24), byte(n>>16), byte(n>>8), byte(n))
}

func rangeToCIDRs(start, end net.IP) []string {
	s := ipToUint32(start)
	e := ipToUint32(end)
	if s > e {
		return nil
	}
	var cidrs []string
	for s <= e {
		sz := e - s + 1

		// max host bits from alignment (trailing zeros of s)
		hostAlign := uint32(0)
		tmp := s
		for tmp&1 == 0 && hostAlign < 32 {
			hostAlign++
			tmp >>= 1
		}

		// max host bits from remaining range size
		hostSize := uint32(0)
		for (uint64(1)<<hostSize) <= uint64(sz) && hostSize < 32 {
			hostSize++
		}
		if hostSize > 0 {
			hostSize--
		}

		hostBits := hostAlign
		if hostSize < hostBits {
			hostBits = hostSize
		}

		prefixLen := 32 - int(hostBits)
		cidrs = append(cidrs, uint32ToIP(s).String()+"/"+strconv.Itoa(prefixLen))
		s += 1 << hostBits
	}
	return cidrs
}

// ========== IP ==========

func (c *VpnClient) getIP() error {
	conn, err := c.tlsConn()
	if err != nil {
		return err
	}

	message := []byte{0x00, 0x00, 0x00, 0x00}
	message = append(message, c.token[:]...)
	message = append(message, []byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff}...)

	_, err = conn.Write(message)
	if err != nil {
		C.go_loge(C.CString("getIP: TLS handshake/Write failed: " + err.Error()))
		conn.Close()
		return err
	}

	hs := conn.HandshakeState
	C.go_logi(C.CString("getIP: TLS negotiated ver=0x" + strconv.FormatUint(uint64(hs.ServerHello.Vers), 16) +
		" cipher=0x" + strconv.FormatUint(uint64(hs.ServerHello.CipherSuite), 16) +
		" compression=" + strconv.Itoa(int(hs.ServerHello.CompressionMethod))))

	reply := make([]byte, 0x80)
	n, err := conn.Read(reply)
	if err != nil {
		conn.Close()
		return err
	}
	replyHex := hex.EncodeToString(reply[:n])
	C.go_logi(C.CString("getIP: reply len=" + strconv.Itoa(n) + " hex=" + replyHex))
	if reply[0] != 0x00 {
		conn.Close()
		return errors.New("unexpected IP reply")
	}

	c.ip = reply[4:8]
	c.ipRev = []byte{c.ip[3], c.ip[2], c.ip[1], c.ip[0]}

	// Keep conn open (critical: closing breaks subsequent handshakes).
	// The reference zju-connect keeps the getIP/query connection alive and
	// NEVER re-issues the getIP request: a second getIP with the same token
	// is treated by the server as a new session login and tears down the
	// already-established data channels (the "connect then drop after a few
	// seconds" symptom). We mirror that behavior here exactly.
	go func() {
		buf := make([]byte, 1500)
		keepCount := 0
		for {
			nn, err := conn.Read(buf)
			if err != nil {
				if keepCount <= 3 || keepCount%50 == 0 {
					C.go_loge(C.CString("getIP keepalive: read err=" + err.Error()))
				}
				return
			}
			if nn > 0 {
				keepCount++
				if keepCount <= 5 {
					C.go_logi(C.CString("getIP keepalive: received " + strconv.Itoa(nn) +
						" bytes hex=" + hex.EncodeToString(buf[:nn])))
				} else if keepCount%50 == 0 {
					C.go_logi(C.CString("getIP keepalive: count=" + strconv.Itoa(keepCount) +
						" last len=" + strconv.Itoa(nn)))
				}
			}
		}
	}()

	// Periodic session keepalive (mirrors the reference zju-connect and the
	// official EasyConnect client). Strict sangfor servers close sessions that
	// stay idle, which shows up as the data channels being dropped a while
	// after connect — this keeps the server-side session alive.
	c.keepAliveOnce.Do(func() {
		go c.sessionKeepAliveLoop()
	})
	return nil
}

// ========== Data Channels ==========

func (c *VpnClient) openDataChannels() error {
	C.go_logi(C.CString("openDataChannels: starting (concurrent)..."))

	type chanResult struct {
		conn *utls.UConn
		err  error
	}
	sendCh := make(chan chanResult, 1)
	recvCh := make(chan chanResult, 1)

	go func() {
		conn, err := c.tlsConn()
		if err != nil {
			sendCh <- chanResult{nil, err}
			return
		}

		msg := []byte{0x05, 0x00, 0x00, 0x00}
		msg = append(msg, c.token[:]...)
		msg = append(msg, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
		msg = append(msg, c.ipRev...)

		_, err = conn.Write(msg)
		if err != nil {
			C.go_loge(C.CString("openDataChannels: send TLS handshake failed: " + err.Error()))
			conn.Close()
			sendCh <- chanResult{nil, err}
			return
		}

		reply := make([]byte, 1500)
		n, err := conn.Read(reply)
		if n > 0 {
			hexLen := n
			if hexLen > 128 {
				hexLen = 128
			}
			C.go_logi(C.CString("openDataChannels: send handshake reply len=" + strconv.Itoa(n) +
				" status=" + strconv.Itoa(int(reply[0])) +
				" cipher=0x" + strconv.FormatUint(uint64(conn.HandshakeState.ServerHello.CipherSuite), 16) +
				" hex=" + hex.EncodeToString(reply[:hexLen])))
		}
		if err != nil {
			C.go_loge(C.CString("openDataChannels: send Read reply failed: " + err.Error()))
			conn.Close()
			sendCh <- chanResult{nil, err}
			return
		}
		if reply[0] != 0x02 {
			conn.Close()
			sendCh <- chanResult{nil, errors.New("send handshake bad status " + strconv.Itoa(int(reply[0])))}
			return
		}
		C.go_logi(C.CString("openDataChannels: send channel established"))
		sendCh <- chanResult{conn, nil}
	}()

	go func() {
		conn, err := c.tlsConn()
		if err != nil {
			recvCh <- chanResult{nil, err}
			return
		}

		msg := []byte{0x06, 0x00, 0x00, 0x00}
		msg = append(msg, c.token[:]...)
		msg = append(msg, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
		msg = append(msg, c.ipRev...)

		_, err = conn.Write(msg)
		if err != nil {
			C.go_loge(C.CString("openDataChannels: recv TLS handshake failed: " + err.Error()))
			conn.Close()
			recvCh <- chanResult{nil, err}
			return
		}

		reply := make([]byte, 1500)
		n, err := conn.Read(reply)
		if n > 0 {
			hexLen := n
			if hexLen > 128 {
				hexLen = 128
			}
			C.go_logi(C.CString("openDataChannels: recv handshake reply len=" + strconv.Itoa(n) +
				" status=" + strconv.Itoa(int(reply[0])) +
				" cipher=0x" + strconv.FormatUint(uint64(conn.HandshakeState.ServerHello.CipherSuite), 16) +
				" hex=" + hex.EncodeToString(reply[:hexLen])))
		}
		if err != nil {
			C.go_loge(C.CString("openDataChannels: recv Read reply failed: " + err.Error()))
			conn.Close()
			recvCh <- chanResult{nil, err}
			return
		}
		if reply[0] != 0x01 {
			conn.Close()
			recvCh <- chanResult{nil, errors.New("recv handshake bad status " + strconv.Itoa(int(reply[0])))}
			return
		}
		C.go_logi(C.CString("openDataChannels: recv channel established"))
		recvCh <- chanResult{conn, nil}
	}()

	sr := <-sendCh
	if sr.err != nil {
		C.go_loge(C.CString("openDataChannels: send channel failed: " + sr.err.Error()))
		rr := <-recvCh
		if rr.conn != nil {
			rr.conn.Close()
		}
		return sr.err
	}

	rr := <-recvCh
	if rr.err != nil {
		C.go_loge(C.CString("openDataChannels: recv channel failed: " + rr.err.Error()))
		sr.conn.Close()
		return rr.err
	}

	c.sendConn = sr.conn
	c.recvConn = rr.conn

	drainBuf := make([]byte, 1500)
	sr.conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	dn, derr := sr.conn.Read(drainBuf)
	sr.conn.SetReadDeadline(time.Time{})
	if dn > 0 {
		hexLen := dn
		if hexLen > 128 {
			hexLen = 128
		}
		C.go_logi(C.CString("openDataChannels: send drain read: " + strconv.Itoa(dn) +
			" bytes hex=" + hex.EncodeToString(drainBuf[:hexLen])))
	}
	if derr != nil {
		C.go_logi(C.CString("openDataChannels: send drain err=" + derr.Error()))
	}

	rr.conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	dn2, derr2 := rr.conn.Read(drainBuf)
	rr.conn.SetReadDeadline(time.Time{})
	if dn2 > 0 {
		hexLen2 := dn2
		if hexLen2 > 128 {
			hexLen2 = 128
		}
		C.go_logi(C.CString("openDataChannels: recv drain read: " + strconv.Itoa(dn2) +
			" bytes hex=" + hex.EncodeToString(drainBuf[:hexLen2])))
	}
	if derr2 != nil {
		C.go_logi(C.CString("openDataChannels: recv drain err=" + derr2.Error()))
	}

	c.connected = true
	C.go_logi(C.CString("openDataChannels: all channels established concurrently, connected=true"))
	return nil
}

func (c *VpnClient) createSendConn() (*utls.UConn, error) {
	if c.token == [48]byte{} {
		return nil, errors.New("token is nil")
	}
	conn, err := c.tlsConn()
	if err != nil {
		return nil, err
	}

	msg := []byte{0x05, 0x00, 0x00, 0x00}
	msg = append(msg, c.token[:]...)
	msg = append(msg, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	msg = append(msg, c.ipRev...)

	_, err = conn.Write(msg)
	if err != nil {
		conn.Close()
		return nil, err
	}

	reply := make([]byte, 1500)
	n, err := conn.Read(reply)
	if err != nil {
		conn.Close()
		return nil, err
	}
	if reply[0] != 0x02 {
		hexLen := n
		if hexLen > 64 {
			hexLen = 64
		}
		conn.Close()
		return nil, errors.New("send handshake bad status " + strconv.Itoa(int(reply[0])) +
			" len=" + strconv.Itoa(n) + " hex=" + hex.EncodeToString(reply[:hexLen]))
	}
	return conn, nil
}

func (c *VpnClient) createRecvConn() (*utls.UConn, error) {
	if c.token == [48]byte{} {
		return nil, errors.New("token is nil")
	}
	conn, err := c.tlsConn()
	if err != nil {
		return nil, err
	}

	msg := []byte{0x06, 0x00, 0x00, 0x00}
	msg = append(msg, c.token[:]...)
	msg = append(msg, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	msg = append(msg, c.ipRev...)

	_, err = conn.Write(msg)
	if err != nil {
		conn.Close()
		return nil, err
	}

	reply := make([]byte, 1500)
	n, err := conn.Read(reply)
	if err != nil {
		conn.Close()
		return nil, err
	}
	if reply[0] != 0x01 {
		hexLen := n
		if hexLen > 64 {
			hexLen = 64
		}
		conn.Close()
		return nil, errors.New("recv handshake bad status " + strconv.Itoa(int(reply[0])) +
			" len=" + strconv.Itoa(n) + " hex=" + hex.EncodeToString(reply[:hexLen]))
	}
	return conn, nil
}

// reconnectDataChannels closes both old data channels and creates new ones
// concurrently. This is called when either channel detects a fatal error.
func (c *VpnClient) reconnectDataChannels() error {
	c.reconnectMu.Lock()
	defer c.reconnectMu.Unlock()

	c.sendLock.Lock()
	if c.sendConn != nil {
		c.sendConn.Close()
		c.sendConn = nil
	}
	c.sendLock.Unlock()

	c.recvLock.Lock()
	if c.recvConn != nil {
		c.recvConn.Close()
		c.recvConn = nil
	}
	c.recvLock.Unlock()

	type chanResult struct {
		conn *utls.UConn
		err  error
	}
	sendCh := make(chan chanResult, 1)
	recvCh := make(chan chanResult, 1)

	go func() {
		conn, err := c.createSendConn()
		sendCh <- chanResult{conn, err}
	}()
	go func() {
		conn, err := c.createRecvConn()
		recvCh <- chanResult{conn, err}
	}()

	sr := <-sendCh
	rr := <-recvCh

	if sr.err != nil {
		if rr.conn != nil {
			rr.conn.Close()
		}
		return sr.err
	}
	if rr.err != nil {
		sr.conn.Close()
		return rr.err
	}

	c.sendLock.Lock()
	c.sendConn = sr.conn
	c.sendLock.Unlock()

	c.recvLock.Lock()
	c.recvConn = rr.conn
	c.recvLock.Unlock()

	C.go_logi(C.CString("reconnectDataChannels: both channels re-established"))
	return nil
}

// ===================== Additional Helpers =====================

func certLogin(c *VpnClient, cert tls.Certificate) error {
	// Get server cert
	addr := "https://" + c.server + "/com/server.crt"
	req, err := http.NewRequest("POST", addr, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	io.Copy(&buf, resp.Body)
	caCertPool := x509.NewCertPool()
	if !caCertPool.AppendCertsFromPEM(buf.Bytes()) {
		return errors.New("failed to parse server cert")
	}

	// Update http client with client cert
	c.httpClient.Transport = &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
			Renegotiation:      tls.RenegotiateOnceAsClient,
			Certificates:       []tls.Certificate{cert},
			RootCAs:            caCertPool,
		},
	}

	// Submit cert login
	addr = "https://" + c.server + "/por/login_cert.csp?anti_replay=1&encrypt=1&type=cs"
	req, err = http.NewRequest("POST", addr, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	resp, err = c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	buf.Reset()
	io.Copy(&buf, resp.Body)
	if !strings.Contains(buf.String(), "<Result>1</Result>") {
		return errors.New("cert login failed")
	}
	return nil
}

// main is required for c-archive
func main() {}
