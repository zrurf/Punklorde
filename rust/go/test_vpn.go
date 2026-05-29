//go:build ignore

package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"io"
	"math/big"
	"net"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	utls "github.com/refraction-networking/utls"
)

type testVpnClient struct {
	server   string
	username string
	password string
	smsCode  string

	twfID string
	token [48]byte
	ip    net.IP
	ipRev []byte

	httpClient *http.Client
	sendConn   *utls.UConn
	recvConn   *utls.UConn
	sendLock   sync.Mutex
	recvLock   sync.Mutex

	resources string
	dnsServer string
	connected bool
}

func newTestClient(server, username, password string) *testVpnClient {
	return &testVpnClient{
		server:   server,
		username: username,
		password: password,
		httpClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			},
		},
	}
}

func (c *testVpnClient) close() {
	if c.sendConn != nil {
		c.sendConn.Close()
	}
	if c.recvConn != nil {
		c.recvConn.Close()
	}
}

func extractXmlText(xmlStr string, tag string) string {
	re := regexp.MustCompile(`<` + tag + `><!\[CDATA\[(.*?)\]\]></` + tag + `>`)
	m := re.FindStringSubmatch(xmlStr)
	if m != nil {
		return m[1]
	}
	re2 := regexp.MustCompile(`<` + tag + `>(.*?)</` + tag + `>`)
	m2 := re2.FindStringSubmatch(xmlStr)
	if m2 != nil {
		return m2[1]
	}
	return ""
}

// ========== Login Flow ==========

func (c *testVpnClient) loginStart() error {
	addr := "https://" + c.server + "/por/login_auth.csp?apiversion=1"
	resp, err := c.httpClient.Get(addr)
	if err != nil {
		return fmt.Errorf("loginStart GET: %w", err)
	}
	defer resp.Body.Close()

	var buf strings.Builder
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return fmt.Errorf("loginStart read body: %w", err)
	}
	body := buf.String()

	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(body)
	if twfMatch == nil {
		return fmt.Errorf("no TwfID in response: %s", body[:min(len(body), 500)])
	}
	c.twfID = twfMatch[1]
	fmt.Printf("[LOGIN] TwfID=%s\n", c.twfID)
	return nil
}

func (c *testVpnClient) loginPassword() error {
	addr := "https://" + c.server + "/por/login_auth.csp?apiversion=1"
	req, err := http.NewRequest("GET", addr, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", "TWFID="+c.twfID)
	req.Header.Set("User-Agent", "EasyConnect_windows")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("loginPassword GET: %w", err)
	}
	defer resp.Body.Close()

	var buf strings.Builder
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return fmt.Errorf("loginPassword read body: %w", err)
	}
	body := buf.String()

	rsaKey := string(regexp.MustCompile(`<RSA_ENCRYPT_KEY>(.*)</RSA_ENCRYPT_KEY>`).FindStringSubmatch(body)[1])
	rsaExpMatch := regexp.MustCompile(`<RSA_ENCRYPT_EXP>(.*)</RSA_ENCRYPT_EXP>`).FindStringSubmatch(body)
	rsaExp := "65537"
	if rsaExpMatch != nil {
		rsaExp = string(rsaExpMatch[1])
	}
	csrfMatch := regexp.MustCompile(`<CSRF_RAND_CODE>(.*)</CSRF_RAND_CODE>`).FindStringSubmatch(body)
	password := c.password
	csrfCode := ""
	if csrfMatch != nil {
		csrfCode = string(csrfMatch[1])
		password += "_" + csrfCode
	}

	pubKey := rsa.PublicKey{}
	pubKey.E, _ = strconv.Atoi(rsaExp)
	modulus := big.Int{}
	modulus.SetString(rsaKey, 16)
	pubKey.N = &modulus
	encryptedPassword, err := rsa.EncryptPKCS1v15(rand.Reader, &pubKey, []byte(password))
	if err != nil {
		return fmt.Errorf("RSA encrypt: %w", err)
	}

	addr = "https://" + c.server + "/por/login_psw.csp?anti_replay=1&encrypt=1&type=cs"
	form := url.Values{
		"svpn_rand_code":    {""},
		"mitm":              {""},
		"svpn_req_randcode": {csrfCode},
		"svpn_name":         {c.username},
		"svpn_password":     {hex.EncodeToString(encryptedPassword)},
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
		return fmt.Errorf("loginPassword POST: %w", err)
	}
	defer resp.Body.Close()
	buf.Reset()
	_, err = io.Copy(&buf, resp.Body)
	if err != nil {
		return fmt.Errorf("loginPassword read result: %w", err)
	}
	respBody := buf.String()

	if strings.Contains(respBody, "<NextService>auth/sms</NextService>") || strings.Contains(respBody, "<NextAuth>2</NextAuth>") {
		fmt.Printf("[LOGIN] SMS required\n")
		return fmt.Errorf("SMS_REQUIRED")
	}
	if strings.Contains(respBody, "<NextService>auth/token</NextService>") || strings.Contains(respBody, "<NextAuth>7</NextAuth>") {
		fmt.Printf("[LOGIN] TOTP required\n")
		return fmt.Errorf("TOTP_REQUIRED")
	}

	if !strings.Contains(respBody, "<Result>1</Result>") {
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
		return fmt.Errorf("login failed: %s", errMsg)
	}

	twfMatch := regexp.MustCompile(`<TwfID>(.*)</TwfID>`).FindStringSubmatch(respBody)
	if twfMatch != nil {
		c.twfID = twfMatch[1]
	}
	fmt.Printf("[LOGIN] Password login success, TwfID=%s\n", c.twfID)
	return nil
}

// ========== Token (with uTLS fingerprint) ==========

func (c *testVpnClient) getToken() error {
	dialConn, err := net.Dial("tcp", c.server)
	if err != nil {
		return err
	}
	defer dialConn.Close()

	conn := utls.UClient(dialConn, &utls.Config{InsecureSkipVerify: true}, utls.HelloGolang)
	defer conn.Close()

	_, err = io.WriteString(conn,
		"GET /por/conf.csp HTTP/1.1\r\nHost: "+c.server+
			"\r\nCookie: TWFID="+c.twfID+
			"\r\n\r\nGET /por/rclist.csp HTTP/1.1\r\nHost: "+c.server+
			"\r\nCookie: TWFID="+c.twfID+"\r\n\r\n",
	)
	if err != nil {
		return fmt.Errorf("getToken write: %w", err)
	}

	sessionID := hex.EncodeToString(conn.HandshakeState.ServerHello.SessionId)

	buf := make([]byte, 8)
	n, err := conn.Read(buf)
	if n == 0 || err != nil {
		return fmt.Errorf("token request invalid: %w", err)
	}

	tokenBytes := []byte(sessionID[:31] + "\x00" + c.twfID)
	copy(c.token[:], tokenBytes[:48])

	fmt.Printf("[TOKEN] token hex=%s\n", hex.EncodeToString(c.token[:]))
	return nil
}

// ========== TLS Connection (matching zju-connect fingerprint) ==========

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

func (c *testVpnClient) tlsConn() (*utls.UConn, error) {
	dialConn, err := net.Dial("tcp", c.server)
	if err != nil {
		return nil, err
	}
	conn := utls.UClient(dialConn, &utls.Config{InsecureSkipVerify: true}, utls.HelloCustom)
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

// ========== IP ==========

func (c *testVpnClient) getIP() error {
	conn, err := c.tlsConn()
	if err != nil {
		return fmt.Errorf("getIP tlsConn: %w", err)
	}

	message := []byte{0x00, 0x00, 0x00, 0x00}
	message = append(message, c.token[:]...)
	message = append(message, []byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff}...)

	_, err = conn.Write(message)
	if err != nil {
		conn.Close()
		return fmt.Errorf("getIP write: %w", err)
	}

	hs := conn.HandshakeState
	fmt.Printf("[IP] TLS negotiated ver=0x%x cipher=0x%x compression=%d\n",
		hs.ServerHello.Vers, hs.ServerHello.CipherSuite, hs.ServerHello.CompressionMethod)

	reply := make([]byte, 0x80)
	n, err := conn.Read(reply)
	if err != nil {
		conn.Close()
		return fmt.Errorf("getIP read: %w", err)
	}
	fmt.Printf("[IP] reply len=%d hex=%s\n", n, hex.EncodeToString(reply[:n]))
	if reply[0] != 0x00 {
		conn.Close()
		return fmt.Errorf("unexpected IP reply status: %d", reply[0])
	}

	c.ip = reply[4:8]
	c.ipRev = []byte{c.ip[3], c.ip[2], c.ip[1], c.ip[0]}

	fmt.Printf("[IP] assigned IP=%d.%d.%d.%d rev=[%d,%d,%d,%d]\n",
		c.ip[0], c.ip[1], c.ip[2], c.ip[3],
		c.ipRev[0], c.ipRev[1], c.ipRev[2], c.ipRev[3])

	go func() {
		buf := make([]byte, 1500)
		for {
			nn, err := conn.Read(buf)
			if err != nil {
				return
			}
			if nn > 0 {
				fmt.Printf("[IP-KEEPALIVE] received %d bytes hex=%s\n", nn, hex.EncodeToString(buf[:nn]))
			}
		}
	}()
	return nil
}

// ========== Data Channels ==========

func (c *testVpnClient) openDataChannels() error {
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
			conn.Close()
			sendCh <- chanResult{nil, fmt.Errorf("send handshake write: %w", err)}
			return
		}

		reply := make([]byte, 1500)
		n, err := conn.Read(reply)
		if n > 0 {
			fmt.Printf("[CHAN-SEND] handshake reply len=%d status=%d cipher=0x%x comp=%d hex=%s\n",
				n, reply[0], conn.HandshakeState.ServerHello.CipherSuite,
				conn.HandshakeState.ServerHello.CompressionMethod,
				hex.EncodeToString(reply[:min(n, 64)]))
		}
		if err != nil {
			conn.Close()
			sendCh <- chanResult{nil, fmt.Errorf("send handshake read: %w", err)}
			return
		}
		if reply[0] != 0x02 {
			conn.Close()
			sendCh <- chanResult{nil, fmt.Errorf("send handshake bad status %d", reply[0])}
			return
		}
		fmt.Printf("[CHAN-SEND] established\n")
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
			conn.Close()
			recvCh <- chanResult{nil, fmt.Errorf("recv handshake write: %w", err)}
			return
		}

		reply := make([]byte, 1500)
		n, err := conn.Read(reply)
		if n > 0 {
			fmt.Printf("[CHAN-RECV] handshake reply len=%d status=%d cipher=0x%x comp=%d hex=%s\n",
				n, reply[0], conn.HandshakeState.ServerHello.CipherSuite,
				conn.HandshakeState.ServerHello.CompressionMethod,
				hex.EncodeToString(reply[:min(n, 64)]))
		}
		if err != nil {
			conn.Close()
			recvCh <- chanResult{nil, fmt.Errorf("recv handshake read: %w", err)}
			return
		}
		if reply[0] != 0x01 {
			conn.Close()
			recvCh <- chanResult{nil, fmt.Errorf("recv handshake bad status %d", reply[0])}
			return
		}
		fmt.Printf("[CHAN-RECV] established\n")
		recvCh <- chanResult{conn, nil}
	}()

	sr := <-sendCh
	if sr.err != nil {
		rr := <-recvCh
		if rr.conn != nil {
			rr.conn.Close()
		}
		return sr.err
	}

	rr := <-recvCh
	if rr.err != nil {
		sr.conn.Close()
		return rr.err
	}

	c.sendConn = sr.conn
	c.recvConn = rr.conn

	// Drain any stale data
	drainBuf := make([]byte, 1500)
	sr.conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	dn, _ := sr.conn.Read(drainBuf)
	sr.conn.SetReadDeadline(time.Time{})
	if dn > 0 {
		fmt.Printf("[CHAN] send drain: %d bytes hex=%s\n", dn, hex.EncodeToString(drainBuf[:min(dn, 64)]))
	}

	rr.conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	dn2, _ := rr.conn.Read(drainBuf)
	rr.conn.SetReadDeadline(time.Time{})
	if dn2 > 0 {
		fmt.Printf("[CHAN] recv drain: %d bytes hex=%s\n", dn2, hex.EncodeToString(drainBuf[:min(dn2, 64)]))
	}

	c.connected = true
	fmt.Printf("[CHAN] both channels established\n")
	return nil
}

// ========== IP/TCP Packet Construction ==========

func checksum(data []byte) uint16 {
	sum := uint32(0)
	for i := 0; i < len(data)-1; i += 2 {
		sum += uint32(data[i])<<8 | uint32(data[i+1])
	}
	if len(data)%2 == 1 {
		sum += uint32(data[len(data)-1]) << 8
	}
	sum = (sum >> 16) + (sum & 0xFFFF)
	sum += sum >> 16
	return uint16(^sum)
}

func buildTCPSYN(srcIP, dstIP net.IP, srcPort, dstPort uint16, seq uint32) []byte {
	// IP header (20 bytes)
	ipHdr := make([]byte, 20)
	ipHdr[0] = 0x45                               // Version=4, IHL=5
	ipHdr[1] = 0x00                               // DSCP/ECN
	binary.BigEndian.PutUint16(ipHdr[2:], 40)     // Total length = 20(IP) + 20(TCP)
	binary.BigEndian.PutUint16(ipHdr[4:], 0x1234) // ID
	binary.BigEndian.PutUint16(ipHdr[6:], 0x4000) // Flags=DF
	ipHdr[8] = 64                                 // TTL
	ipHdr[9] = 6                                  // Protocol=TCP
	// Checksum placeholder at [10:12]
	copy(ipHdr[12:16], srcIP.To4())
	copy(ipHdr[16:20], dstIP.To4())

	ipCsum := checksum(ipHdr)
	binary.BigEndian.PutUint16(ipHdr[10:], ipCsum)

	// TCP header (20 bytes, SYN)
	tcpHdr := make([]byte, 20)
	binary.BigEndian.PutUint16(tcpHdr[0:], srcPort)
	binary.BigEndian.PutUint16(tcpHdr[2:], dstPort)
	binary.BigEndian.PutUint32(tcpHdr[4:], seq)
	// Ack=0
	tcpHdr[12] = 0x50                              // DataOffset=5 (20 bytes)
	tcpHdr[13] = 0x02                              // Flags=SYN
	binary.BigEndian.PutUint16(tcpHdr[14:], 64240) // Window
	// Checksum placeholder at [16:18]
	// Urgent=0

	// TCP pseudo-header for checksum
	pseudo := make([]byte, 12)
	copy(pseudo[0:4], srcIP.To4())
	copy(pseudo[4:8], dstIP.To4())
	pseudo[8] = 0
	pseudo[9] = 6                               // Protocol=TCP
	binary.BigEndian.PutUint16(pseudo[10:], 20) // TCP header length

	tcpCsum := checksum(append(pseudo, tcpHdr...))
	binary.BigEndian.PutUint16(tcpHdr[16:], tcpCsum)

	return append(ipHdr, tcpHdr...)
}

func buildTCPPacket(srcIP, dstIP net.IP, srcPort, dstPort uint16, seq, ack uint32, flags uint8, payload []byte) []byte {
	ipHdr := make([]byte, 20)
	ipHdr[0] = 0x45
	ipHdr[1] = 0x00
	totalLen := 20 + 20 + len(payload)
	binary.BigEndian.PutUint16(ipHdr[2:], uint16(totalLen))
	binary.BigEndian.PutUint16(ipHdr[4:], 0x1235)
	binary.BigEndian.PutUint16(ipHdr[6:], 0x4000)
	ipHdr[8] = 64
	ipHdr[9] = 6
	copy(ipHdr[12:16], srcIP.To4())
	copy(ipHdr[16:20], dstIP.To4())
	ipCsum := checksum(ipHdr)
	binary.BigEndian.PutUint16(ipHdr[10:], ipCsum)

	tcpHdr := make([]byte, 20)
	binary.BigEndian.PutUint16(tcpHdr[0:], srcPort)
	binary.BigEndian.PutUint16(tcpHdr[2:], dstPort)
	binary.BigEndian.PutUint32(tcpHdr[4:], seq)
	binary.BigEndian.PutUint32(tcpHdr[8:], ack)
	tcpHdr[12] = 0x50 // DataOffset=5
	tcpHdr[13] = flags
	binary.BigEndian.PutUint16(tcpHdr[14:], 64240)

	pseudo := make([]byte, 12)
	copy(pseudo[0:4], srcIP.To4())
	copy(pseudo[4:8], dstIP.To4())
	pseudo[8] = 0
	pseudo[9] = 6
	binary.BigEndian.PutUint16(pseudo[10:], uint16(20+len(payload)))

	tcpSegment := append(tcpHdr, payload...)
	tcpCsum := checksum(append(pseudo, tcpSegment...))
	binary.BigEndian.PutUint16(tcpSegment[16:], tcpCsum)

	return append(ipHdr, tcpSegment...)
}

func parseIPPacket(data []byte) (srcIP, dstIP net.IP, protocol uint8, payload []byte, totalLen int) {
	if len(data) < 20 {
		return nil, nil, 0, nil, 0
	}
	ihl := (data[0] & 0x0F) * 4
	totalLen = int(binary.BigEndian.Uint16(data[2:4]))
	protocol = data[9]
	srcIP = net.IP(data[12:16])
	dstIP = net.IP(data[16:20])
	if int(ihl) < len(data) && totalLen <= len(data) {
		payload = data[ihl:totalLen]
	}
	return
}

func parseTCPHeader(data []byte) (srcPort, dstPort uint16, seq, ack uint32, flags uint8, dataLen int, payload []byte) {
	if len(data) < 20 {
		return 0, 0, 0, 0, 0, 0, nil
	}
	srcPort = binary.BigEndian.Uint16(data[0:2])
	dstPort = binary.BigEndian.Uint16(data[2:4])
	seq = binary.BigEndian.Uint32(data[4:8])
	ack = binary.BigEndian.Uint32(data[8:12])
	flags = data[13]
	dataOffset := (data[12] >> 4) * 4
	dataLen = len(data) - int(dataOffset)
	if dataLen > 0 && int(dataOffset) < len(data) {
		payload = data[dataOffset:]
	}
	return
}

// ========== HTTP via VPN ==========

func (c *testVpnClient) httpGetViaVPN(dstIPStr string, dstPort int, path string) error {
	dstIP := net.ParseIP(dstIPStr)
	if dstIP == nil {
		return fmt.Errorf("invalid dest IP: %s", dstIPStr)
	}
	dstIP = dstIP.To4()
	if dstIP == nil {
		return fmt.Errorf("need IPv4 dest")
	}

	srcIP := c.ip.To4()
	srcPort := uint16(50000 + (time.Now().UnixNano() % 10000))

	mySeq := uint32(time.Now().UnixNano() & 0xFFFFFFFF)

	// Step 1: Send TCP SYN
	synPkt := buildTCPSYN(srcIP, dstIP, srcPort, uint16(dstPort), mySeq)
	fmt.Printf("[HTTP-VPN] sending TCP SYN to %s:%d\n", dstIPStr, dstPort)

	c.sendLock.Lock()
	n, err := c.sendConn.Write(synPkt)
	c.sendLock.Unlock()
	if err != nil {
		return fmt.Errorf("send SYN: %w", err)
	}
	fmt.Printf("[HTTP-VPN] SYN sent: %d bytes\n", n)

	// Step 2: Wait for SYN-ACK on recv channel
	timeout := time.After(10 * time.Second)
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()

	recvBuf := make([]byte, 4096)
	var serverSeq, serverAck uint32
	var gotSynAck bool

	fmt.Printf("[HTTP-VPN] waiting for SYN-ACK...\n")
	for !gotSynAck {
		select {
		case <-timeout:
			return fmt.Errorf("timeout waiting for SYN-ACK")
		case <-ticker.C:
			c.recvLock.Lock()
			rn, rerr := c.recvConn.Read(recvBuf)
			c.recvLock.Unlock()
			if rerr != nil {
				continue
			}
			if rn > 0 {
				fmt.Printf("[HTTP-VPN] recv %d bytes hex=%s\n", rn, hex.EncodeToString(recvBuf[:min(rn, 80)]))
				sip, dip, proto, _, _ := parseIPPacket(recvBuf[:rn])
				if proto == 6 {
					sp, dp, seq, ack, flags, _, tcpPayload := parseTCPHeader(recvBuf[20:rn])
					fmt.Printf("[HTTP-VPN] TCP %s:%d->%s:%d seq=%d ack=%d flags=0x%02x payload=%d\n",
						sip, sp, dip, dp, seq, ack, flags, len(tcpPayload))
					if flags&0x12 == 0x12 && dp == srcPort { // SYN-ACK
						serverSeq = seq
						serverAck = ack
						gotSynAck = true
						fmt.Printf("[HTTP-VPN] Got SYN-ACK! serverSeq=%d serverAck=%d\n", serverSeq, serverAck)
					}
				}
			}
		}
	}

	// Step 3+4: Send ACK + HTTP GET in one packet (merge handshake completion with data)
	mySeq++ // SYN consumes one sequence number
	httpReq := fmt.Sprintf("GET %s HTTP/1.1\r\nHost: %s\r\nUser-Agent: PunklordeVPN/1.0\r\nConnection: close\r\n\r\n", path, dstIPStr)
	httpPkt := buildTCPPacket(srcIP, dstIP, srcPort, uint16(dstPort), mySeq, serverSeq+1, 0x18, []byte(httpReq))
	fmt.Printf("[HTTP-VPN] sending ACK+HTTP (seq=%d, ack=%d, flags=0x18, payloadLen=%d)\n", mySeq, serverSeq+1, len(httpReq))
	c.sendLock.Lock()
	n, err = c.sendConn.Write(httpPkt)
	c.sendLock.Unlock()
	if err != nil {
		return fmt.Errorf("send ACK+HTTP: %w", err)
	}
	fmt.Printf("[HTTP-VPN] ACK+HTTP sent: %d bytes\n", n)

	// Step 5: Read HTTP response
	// Step 5: Read HTTP response (with ACKs to avoid retransmit)
	fmt.Printf("[HTTP-VPN] waiting for HTTP response...\n")
	readDeadline := time.Now().Add(30 * time.Second)
	var responseData []byte
	receivedSeqs := make(map[uint32]bool)
	gotResponse := false

	for {
		c.recvConn.SetReadDeadline(readDeadline)
		recvBuf2 := make([]byte, 8192)
		c.recvLock.Lock()
		rn2, rerr2 := c.recvConn.Read(recvBuf2)
		c.recvLock.Unlock()
		if rerr2 != nil {
			if gotResponse {
				fmt.Printf("[HTTP-VPN] read done: %v\n", rerr2)
				break
			}
			if time.Now().After(readDeadline) {
				return fmt.Errorf("timeout waiting for HTTP response")
			}
			continue
		}
		if rn2 > 0 {
			_, _, proto, ippayload, _ := parseIPPacket(recvBuf2[:rn2])
			if proto == 6 {
				tcpPayload2 := ippayload
				if len(tcpPayload2) >= 20 {
					_, _, seq, _, flags, _, tcpBody := parseTCPHeader(tcpPayload2)
					if len(tcpBody) > 0 && !receivedSeqs[seq] {
						receivedSeqs[seq] = true
						gotResponse = true
						responseData = append(responseData, tcpBody...)
						if len(receivedSeqs)%50 == 0 {
							fmt.Printf("[HTTP-VPN] recv: %d/%d bytes\n",
								len(responseData), len(responseData))
						}
						// Send ACK for received data
						myNextSeq := mySeq + uint32(len([]byte(httpReq)))
						ackSeq := seq + uint32(len(tcpBody))
						ackPkt := buildTCPPacket(srcIP, dstIP, srcPort, uint16(dstPort), myNextSeq, ackSeq, 0x10, nil)
						c.sendLock.Lock()
						c.sendConn.Write(ackPkt)
						c.sendLock.Unlock()
						// Extend deadline on each received segment
						readDeadline = time.Now().Add(10 * time.Second)
					} else if len(tcpBody) > 0 {
						// Duplicate (retransmit) - re-send ACK
						myNextSeq := mySeq + uint32(len([]byte(httpReq)))
						ackSeq := seq + uint32(len(tcpBody))
						ackPkt := buildTCPPacket(srcIP, dstIP, srcPort, uint16(dstPort), myNextSeq, ackSeq, 0x10, nil)
						c.sendLock.Lock()
						c.sendConn.Write(ackPkt)
						c.sendLock.Unlock()
					}
					if flags&0x01 != 0 {
						fmt.Printf("[HTTP-VPN] got FIN, connection closing\n")
						break
					}
					if flags&0x04 != 0 {
						fmt.Printf("[HTTP-VPN] got RST\n")
						break
					}
				}
			}
		}
	}
	response := string(responseData)
	headerEnd := strings.Index(response, "\r\n\r\n")
	fmt.Printf("\n===== HTTP RESPONSE HEADERS =====\n")
	if headerEnd >= 0 {
		fmt.Printf("%s\n", response[:headerEnd])
		fmt.Printf("===== XML BODY (first 500 chars) =====\n%s\n", response[headerEnd+4:min(len(response), headerEnd+4+500)])
	} else {
		fmt.Printf("%s\n", response[:min(len(response), 500)])
	}
	fmt.Printf("===== TOTAL: %d bytes =====\n", len(responseData))
	return nil
}

// ========== Main ==========

func main() {
	if len(os.Args) < 4 {
		fmt.Println("Usage: go run test_vpn.go <server> <username> <password>")
		os.Exit(1)
	}

	server := os.Args[1]
	username := os.Args[2]
	password := os.Args[3]

	client := newTestClient(server, username, password)

	fmt.Println("========== Step 1: Login ==========")
	err := client.loginStart()
	if err != nil {
		fmt.Fprintf(os.Stderr, "loginStart failed: %v\n", err)
		os.Exit(1)
	}

	err = client.loginPassword()
	if err != nil {
		if err.Error() == "SMS_REQUIRED" {
			fmt.Println("SMS code required! Enter code:")
			var code string
			fmt.Scanln(&code)
			client.smsCode = code
			// TODO: implement SMS login if needed
			fmt.Println("SMS login not yet implemented in test")
			os.Exit(1)
		}
		fmt.Fprintf(os.Stderr, "loginPassword failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n========== Step 2: Get Token ==========")
	err = client.getToken()
	if err != nil {
		fmt.Fprintf(os.Stderr, "getToken failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n========== Step 3: Get IP ==========")
	err = client.getIP()
	if err != nil {
		fmt.Fprintf(os.Stderr, "getIP failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n========== Step 4: Open Data Channels ==========")
	err = client.openDataChannels()
	if err != nil {
		fmt.Fprintf(os.Stderr, "openDataChannels failed: %v\n", err)
		os.Exit(1)
	}

	defer client.close()

	fmt.Println("\n========== Step 5: HTTP Request via VPN ==========")
	err = client.httpGetViaVPN("172.20.2.228", 80, "/file/face/")
	if err != nil {
		fmt.Fprintf(os.Stderr, "HTTP via VPN failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n========== DONE ==========")
}
