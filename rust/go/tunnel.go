package main

/*
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef void (*DataCallback)(void* ctx, const uint8_t* data, int len);
*/
import "C"
import (
	"crypto/tls"
	"io"
	"net"
	"net/http"
	"sync"
	"unsafe"

	utls "github.com/refraction-networking/utls"
)

// EasyConnectClient 代表一个VPN客户端实例
type EasyConnectClient struct {
	id         int
	server     string // host:port
	username   string
	password   string
	totpSecret string
	tlsCert    tls.Certificate // 证书登录用
	twfID      string
	token      [48]byte
	ip         net.IP
	ipReverse  []byte
	sendConn   *utls.UConn
	recvConn   *utls.UConn
	httpClient *http.Client

	// 资源数据
	ipResources     []IPResource
	domainResources map[string]DomainResource
	dnsResource     map[string]net.IP
	dnsServer       string
}

// IPResource 定义IP资源
type IPResource struct {
	IPMin    net.IP
	IPMax    net.IP
	PortMin  int
	PortMax  int
	Protocol string
}

// DomainResource 定义域名资源
type DomainResource struct {
	PortMin  int
	PortMax  int
	Protocol string
}

// 全局客户端映射
var (
	clients = make(map[int]*EasyConnectClient)
	nextID  = 1
	mu      sync.Mutex
)

// 导出C函数

//export EC_New
func EC_New(server, username, password, totpSecret *C.char) C.int {
	mu.Lock()
	defer mu.Unlock()
	id := nextID
	nextID++
	client := &EasyConnectClient{
		id:         id,
		server:     C.GoString(server),
		username:   C.GoString(username),
		password:   C.GoString(password),
		totpSecret: C.GoString(totpSecret),
		httpClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			},
		},
	}
	clients[id] = client
	return C.int(id)
}

//export EC_Free
func EC_Free(id C.int) {
	mu.Lock()
	defer mu.Unlock()
	if c, ok := clients[int(id)]; ok {
		if c.sendConn != nil {
			c.sendConn.Close()
		}
		if c.recvConn != nil {
			c.recvConn.Close()
		}
		delete(clients, int(id))
	}
}

//export EC_LoginStart
func EC_LoginStart(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("") // 返回空表示失败
	}
	twfID, err := c.loginStart()
	if err != nil {
		return C.CString("")
	}
	c.twfID = twfID
	return C.CString(twfID)
}

//export EC_LoginPassword
func EC_LoginPassword(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("client not found")
	}
	err := c.loginPassword()
	if err != nil {
		return C.CString(err.Error())
	}
	return nil // 成功返回NULL
}

//export EC_LoginSMS
func EC_LoginSMS(id C.int, code *C.char) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("client not found")
	}
	err := c.loginSMS(C.GoString(code))
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export EC_LoginTOTP
func EC_LoginTOTP(id C.int, code *C.char) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("client not found")
	}
	err := c.loginTOTP(C.GoString(code))
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export EC_GetToken
func EC_GetToken(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("client not found")
	}
	err := c.getToken()
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export EC_GetResources
func EC_GetResources(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("")
	}
	xmlData, err := c.getResources()
	if err != nil {
		return C.CString("")
	}
	return C.CString(xmlData)
}

//export EC_GetIP
func EC_GetIP(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("")
	}
	err := c.getIP()
	if err != nil {
		return C.CString("")
	}
	return C.CString(c.ip.String())
}

//export EC_OpenDataChannels
func EC_OpenDataChannels(id C.int) *C.char {
	c := getClient(int(id))
	if c == nil {
		return C.CString("client not found")
	}
	err := c.openDataChannels()
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export EC_ReadRecv
func EC_ReadRecv(id C.int, buf unsafe.Pointer, len C.int) C.int {
	c := getClient(int(id))
	if c == nil || c.recvConn == nil {
		return -1
	}
	data := make([]byte, len)
	n, err := c.recvConn.Read(data)
	if err != nil {
		return -1
	}
	C.memcpy(buf, unsafe.Pointer(&data[0]), C.size_t(n))
	return C.int(n)
}

//export EC_WriteSend
func EC_WriteSend(id C.int, buf unsafe.Pointer, len C.int) C.int {
	c := getClient(int(id))
	if c == nil || c.sendConn == nil {
		return -1
	}
	data := C.GoBytes(buf, len)
	n, err := c.sendConn.Write(data)
	if err != nil {
		return -1
	}
	return C.int(n)
}

// 辅助函数
func getClient(id int) *EasyConnectClient {
	mu.Lock()
	defer mu.Unlock()
	return clients[id]
}

// ---------- EasyConnectClient 方法实现 ----------
// 以下方法参考 ZJU-Connect 的 client 包实现，这里仅给出框架，需要填充具体逻辑

func (c *EasyConnectClient) loginStart() (string, error) {
	// 发送 GET /por/login_auth.csp?apiversion=1
	// 解析XML，提取 TwfID, RSA key, RSA exp, CSRF rand code 等
	// 参考 ZJU-Connect client/request.go 中的 requestTwfID 和 loginAuthAndPsw
	// 这里省略详细实现，返回示例 TwfID
	return "dummy_twfid", nil
}

func (c *EasyConnectClient) loginPassword() error {
	// 使用 RSA 加密密码，发送 POST /por/login_psw.csp
	// 处理二次认证需求（SMS/TOTP/Cert）
	// 参考 ZJU-Connect client/request.go 中的 loginAuthAndPsw
	return nil
}

func (c *EasyConnectClient) loginSMS(code string) error {
	// 发送 SMS 验证码
	// 参考 ZJU-Connect client/request.go 中的 loginSMS
	return nil
}

func (c *EasyConnectClient) loginTOTP(code string) error {
	// 发送 TOTP 验证码
	// 参考 ZJU-Connect client/request.go 中的 loginTOTP
	return nil
}

func (c *EasyConnectClient) getToken() error {
	// 建立特殊 TLS 连接，发送合并请求，从 ServerHello.SessionId 提取 token
	// 参考 ZJU-Connect client/request.go 中的 requestToken
	return nil
}

func (c *EasyConnectClient) getResources() (string, error) {
	// 发送 GET /por/rclist.csp，返回 XML 字符串
	// 参考 ZJU-Connect client/request.go 中的 requestResources
	return "", nil
}

func (c *EasyConnectClient) getIP() error {
	// 建立 TLS 连接，发送 IP 请求包，获取分配的 IP
	// 参考 ZJU-Connect client/request.go 中的 requestIP
	return nil
}

func (c *EasyConnectClient) openDataChannels() error {
	// 建立 SendConn 和 RecvConn 两个 TLS 连接
	// 参考 ZJU-Connect client/protocol.go 中的 SendConn 和 RecvConn
	return nil
}

// 以下为辅助类型，用于 XML 解析等，实际实现需要从 ZJU-Connect 复制

type fakeHeartBeatExtension struct{}

func (e *fakeHeartBeatExtension) Len() int { return 5 }
func (e *fakeHeartBeatExtension) Read(b []byte) (int, error) {
	if len(b) < 5 {
		return 0, io.ErrShortBuffer
	}
	b[0] = 0x0f
	b[1] = 0x00
	b[2] = 0x00
	b[3] = 0x01
	b[4] = 0x01
	return 5, io.EOF
}

func main() {} // 必须有一个 main 函数，但作为库不需要
