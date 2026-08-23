import 'package:punklorde/module/platform/unify/base.dart';

/// 中传统一认证平台（支持二次认证）
class CucUnifyBasePlatform extends UnifyBasePlatform {
  static const Set<String> cookieDomain = {
    "https://sso.cuc.edu.cn",
    "https://sso.cuc.edu.cn/authserver",
  };

  @override
  String get serverPrefix => "https://sso.cuc.edu.cn/authserver";

  @override
  Set<String> get cookieDomains => cookieDomain;

  @override
  bool get supportReAuth => true;
}