/// 登录方式
enum ChaoxingLoginMethod {
  pwd, // 密码登录
  sms, // 短信登录
  qrcode, // 二维码登录
}

/// 登录配置
class ChaoxingLoginConfig {
  final ChaoxingLoginMethod method; // 登录方式
  final String phone; // 手机号
  final String value; // 密码或验证码或二维码token
  final bool useIosUa; // 是否使用iOS的UA

  const ChaoxingLoginConfig({
    required this.method,
    required this.phone,
    required this.value,
    required this.useIosUa,
  });
}
