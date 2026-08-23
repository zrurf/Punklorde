import 'package:punklorde/module/network/interceptor/cqupt.dart';
import 'package:punklorde/module/platform/unify/base.dart';

/// 重邮统一认证平台
class CquptUnifyBasePlatform extends UnifyBasePlatform {
  static const Set<String> cookieDomain = {
    "https://ids.cqupt.edu.cn",
    "https://ids.cqupt.edu.cn/authserver",
  };

  CquptUnifyBasePlatform() : super(interceptors: [CquptForwardInterceptor()]);

  @override
  String get serverPrefix => "https://ids.cqupt.edu.cn/authserver";

  @override
  Set<String> get cookieDomains => cookieDomain;
}