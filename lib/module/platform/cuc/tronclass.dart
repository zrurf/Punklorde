import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/core/account/view/widget/login_panel.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/platform/cuc/unify.dart';
import 'package:punklorde/module/platform/unify/base.dart';
import 'package:punklorde/module/service/vault/vault_dialog.dart';
import 'package:punklorde/utils/ua.dart';
import 'package:punklorde/utils/uuid.dart';

class CucTronclassPlatform extends Platform {
  static const String _domainService = "courses.cuc.edu.cn";
  static const String _domainCas = "sso.cuc.edu.cn";
  static const String _domainRelay = "identity.courses.cuc.edu.cn";
  static const String _domainMobile = "mobile.courses.cuc.edu.cn";

  static const String _baseUrl = "https://$_domainService";
  static const String _mobileBaseUrl = "https://$_domainMobile";
  static const String _apiVerify = "$_baseUrl/statistics/api/user-visits";
  static const String _apiLogin = "$_baseUrl/login";
  static const String _apiProfile = "$_baseUrl/api/profile";

  @override
  String get id => "cuc_tron";

  @override
  String get name => "畅课";

  @override
  String get descript => "用于中传畅课平台";

  @override
  String get loginAccountType => "cuc_unify";

  late final Dio _dio;

  late final CucUnifyBasePlatform _unifyBasePlatform;

  late final CookieJar _cookieJar;

  CucTronclassPlatform() {
    _cookieJar = CookieJar();
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {"User-Agent": UAUtil.getUA(.wechat)},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _unifyBasePlatform = CucUnifyBasePlatform();
  }

  /// 手动跟随重定向
  Future<Response> _followRedirects(
    Response resp,
    bool Function(Response resp) condition,
  ) async {
    const maxRedirects = 10;
    var redirectCount = 0;

    while (redirectCount < maxRedirects) {
      if (condition(resp)) {
        break;
      }

      final location = resp.headers["location"]?.first;
      if (location == null || location.isEmpty) {
        break;
      }

      resp = await _dio.getUri(Uri.parse(location));
      redirectCount++;
    }
    return resp;
  }

  Future<AuthCredential?> _login(
    BuildContext context,
    String uid,
    String pwd,
    bool longTerm,
  ) async {
    await _cookieJar.deleteAll();
    final CookieManager cookieManager = CookieManager(_cookieJar);
    _dio.interceptors.add(cookieManager);
    String? sessionId;
    try {
      final r1 = await _dio.get(_apiLogin);
      final r2 = await _followRedirects(r1, (resp) {
        final location = resp.headers["location"]?.first;
        if (location == null || location.isEmpty) {
          return true;
        }
        final uri = Uri.parse(location);
        return ((resp.realUri.host == _domainService &&
                resp.realUri.path == "/login" &&
                uri.host == _domainService)) ||
            (uri.host == _domainCas);
      });
      final location = r2.headers["location"]?.first;
      if (location == null || location.isEmpty) {
        return null;
      }
      final uri1 = Uri.parse(location);
      switch (uri1.host) {
        case _domainCas:
          final url2 = uri1.queryParameters["service"];
          if (url2 == null) return null;
          final url3 = await _unifyBasePlatform.passwordLogin(
            url2,
            uid,
            pwd,
            longTerm,
            _cookieJar,
            onReAuth: (param) => _showReAuth(context, param),
          );
          if (url3 == null) return null;
          final r3 = await _dio.get(url3);
          final r4 = await _followRedirects(r3, (resp) {
            return (resp.realUri.host == _domainService &&
                resp.realUri.path == "/login");
          });
          sessionId = r4.headers["X-SESSION-ID"]?.first;
        case _domainService:
          sessionId = r2.headers["X-SESSION-ID"]?.first;
        default:
          return null;
      }
      if (sessionId == null) return null;
      // 移动端与桌面端不同域：将桌面端域下的 cookie 复制给移动端域，
      // 供通用畅课 WebView 在 mobile 域下使用
      final desktopCookies = await _cookieJar.loadForRequest(
        Uri.parse(_baseUrl),
      );
      if (desktopCookies.isNotEmpty) {
        await _cookieJar.saveFromResponse(
          Uri.parse(_mobileBaseUrl),
          desktopCookies,
        );
      }
      final r5 = await _dio.get(
        _apiProfile,
        options: Options(
          headers: {
            "User-Agent": UAUtil.getUA(.raw),
            "X-SESSION-ID": sessionId,
          },
        ),
      );

      return AuthCredential(
        guest: false,
        type: id,
        id: r5.data["id"].toString(),
        name: r5.data["name"].toString(),
        token: sessionId,
        expireAt: DateTime.now().addDays(1),
        ext: Map.from({
          "uid": uid,
          "uuid": DeterministicUuidUtil.generate(
            "${r5.data["id"].toString()}_$uid",
          ),
          "cookie": await serializeCookieJar(_cookieJar, {
            _baseUrl,
            _mobileBaseUrl,
            "https://$_domainRelay",
            ...CucUnifyBasePlatform.cookieDomain,
          }),
        }),
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 二次认证交互
  Future<Map<String, String>?> _showReAuth(
    BuildContext context,
    UnifyReAuthParam param,
  ) async {
    // 登录流程中的全屏加载器先移除，否则遮挡二次认证输入
    if (context.mounted) context.loaderOverlay.hide();
    final completer = Completer<Map<String, String>?>();
    await showFSheet(
      context: context,
      builder: (sheetContext) => _CucReAuthView(
        param: param,
        unify: _unifyBasePlatform,
        cookieJar: _cookieJar,
        onConfirm: (result) {
          Navigator.of(sheetContext).pop();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        },
      ),
      side: .btt,
    );
    return completer.future;
  }

  Future<AuthCredential?> _refresh(AuthCredential credential) async {
    final rawMap = credential.ext!['cookie'] as Map<Object?, Object?>;
    final cookieMap = rawMap.map((key, value) {
      return MapEntry(key.toString(), List<String>.from(value as List));
    });
    final cookie = await deserializeCookieJar(cookieMap);
    final CookieManager cookieManager = CookieManager(cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r1 = await _dio.get(_apiLogin);
      final r2 = await _followRedirects(r1, (resp) {
        final location = resp.headers["location"]?.first;
        if (location == null || location.isEmpty) {
          return true;
        }
        final uri = Uri.parse(location);
        return (resp.realUri.host == _domainService &&
            resp.realUri.path == "/login" &&
            uri.host == _domainService);
      });
      if (r2.realUri.host != _domainService) return null;
      final sessionId = r2.headers["X-SESSION-ID"]?.first;
      return credential.copyWith(
        token: sessionId,
        expireAt: DateTime.now().addDays(1),
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  @override
  Future<AuthCredential?> login(BuildContext context, bool isGuest) async {
    final completer = Completer<Map<String, String>?>();

    await showFSheet(
      context: context,
      builder: (sheetContext) => LoginPanel(
        platform: name,
        desc: descript,
        inputEntries: [
          LoginInputEntry(
            id: "id",
            lable: t.common.studnet_id,
            isPwd: false,
            defaultValue: '',
            hint: t.common.studnet_id,
          ),
          LoginInputEntry(
            id: "pwd",
            lable: t.common.password,
            isPwd: true,
            defaultValue: '',
            hint: t.common.password,
          ),
        ],
        vaultAccountType: loginAccountType,
        onConfirm: (values) {
          Navigator.of(sheetContext).pop();
          if (!completer.isCompleted) {
            completer.complete(values);
          }
        },
      ),
      side: .btt,
    );

    final result = await completer.future;

    if (result != null && result['id'] != null && result['pwd'] != null) {
      if (!context.mounted) return null;
      final loader = context.loaderOverlay;
      loader.show();
      AuthCredential? credential;
      try {
        credential = await _login(context, result['id']!, result['pwd']!, true);
      } finally {
        loader.hide();
      }
      if (credential != null && !isGuest && context.mounted) {
        showVaultSavePrompt(
          context,
          schoolId: currentSchoolSignal.value?.id ?? '',
          platformId: id,
          accountType: loginAccountType,
          username: result['id']!,
          password: result['pwd']!,
        );
      }
      return credential?.copyWith(guest: isGuest);
    }

    return null;
  }

  @override
  Future<void> logout(AuthCredential credential) async {}

  @override
  Future<AuthCredential?> refresh(AuthCredential oldCredential) async {
    return await _refresh(oldCredential);
  }

  @override
  Future<bool> validate(AuthCredential credential) async {
    final resp = await _dio.get(
      _apiVerify,
      options: Options(
        headers: {
          "User-Agent": UAUtil.getUA(.raw),
          "Cookie": "session=${credential.token}",
        },
      ),
    );
    final status = resp.statusCode;
    if (status == null) return false;
    return status >= 200 && status < 300;
  }
}

final platCucTronclass = CucTronclassPlatform();

/// 动态码类型名映射（对应 reAuth.js 中的 authCodeTypeName）
String _dynamicCodeTypeName(String reAuthType) {
  return switch (reAuthType) {
    '4' => 'reAuthWChatDynamicCodeType',
    '5' => 'reAuthCpdailyDynamicCodeType',
    '11' => 'reAuthEmailDynamicCodeType',
    '12' => 'reAuthDingTalkDynamicCodeType',
    '13' => 'reAuthWeLinkDynamicCodeType',
    _ => 'reAuthDynamicCodeType',
  };
}

/// 二次认证视图
class _CucReAuthView extends StatefulWidget {
  final UnifyReAuthParam param;
  final CucUnifyBasePlatform unify;
  final CookieJar cookieJar;
  final void Function(Map<String, String>) onConfirm;

  const _CucReAuthView({
    required this.param,
    required this.unify,
    required this.cookieJar,
    required this.onConfirm,
  });

  @override
  State<_CucReAuthView> createState() => _CucReAuthViewState();
}

class _CucReAuthViewState extends State<_CucReAuthView> {
  final TextEditingController _codeController = TextEditingController();
  bool _sending = false;
  int? _countdown; // 可再次发送倒计时（秒），null 表示可发送
  Timer? _countdownTimer;

  bool get _isPasswordType {
    final t = widget.param.reAuthType;
    return t.isEmpty || t == "2" || t == "7";
  }

  bool get _isDynamicCodeType {
    return const [
      "3",
      "4",
      "5",
      "11",
      "12",
      "13",
    ].contains(widget.param.reAuthType);
  }

  bool get _isOtpType => widget.param.reAuthType == "10";

  @override
  void dispose() {
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending || _countdown != null) return;
    setState(() => _sending = true);
    final codeTime = await widget.unify.sendReAuthDynamicCode(
      widget.param.reAuthUserId ?? '',
      _dynamicCodeTypeName(widget.param.reAuthType),
      widget.cookieJar,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    showFToast(
      context: context,
      variant: (codeTime != null) ? .primary : .destructive,
      alignment: .topCenter,
      title: Text(
        (codeTime != null)
            ? t.notice.sms_code_sent
            : t.notice.sms_code_send_failed,
      ),
      duration: const Duration(seconds: 2),
      icon: Icon(
        (codeTime != null) ? LucideIcons.circleCheck : LucideIcons.circleX,
      ),
    );
    if (codeTime != null) {
      _startCountdown(codeTime);
    }
  }

  /// 开始“可再次发送”倒计时
  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _countdown = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remain = _countdown ?? 1;
      if (remain <= 1) {
        t.cancel();
        setState(() => _countdown = null);
      } else {
        setState(() => _countdown = remain - 1);
      }
    });
  }

  Future<void> _submit() async {
    final param = widget.param;
    final submit = <String, String>{
      "service": param.service,
      "reAuthType": param.reAuthType,
      "isMultifactor": param.isMultifactor,
      "password": "",
      "dynamicCode": "",
      "uuid": "",
      "answer1": "",
      "answer2": "",
      "otpCode": "",
    };
    if (_isPasswordType) {
      final salt = param.pwdEncryptSalt;
      if (salt == null || salt.isEmpty) return;
      submit["password"] = await widget.unify.encodePwd(
        _codeController.text,
        salt,
      );
    } else if (_isDynamicCodeType) {
      submit["dynamicCode"] = _codeController.text;
    } else if (_isOtpType) {
      submit["otpCode"] = _codeController.text;
    }
    if (!mounted) return;
    widget.onConfirm(submit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final supported = _isPasswordType || _isDynamicCodeType || _isOtpType;
    return Scaffold(
      // showFSheet 路由层已整体上移避让键盘，内部无需再次 resize
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          height: .infinity,
          width: .infinity,
          decoration: BoxDecoration(
            color: colors.background,
            border: .symmetric(horizontal: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            padding: const .symmetric(horizontal: 16, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Column(
                  spacing: 8,
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Text(
                      t.notice.reauth_title,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                    ),
                    Text(
                      t.notice.reauth_hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    if (!supported)
                      Text(
                        t.notice.reauth_unsupported,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.destructive,
                        ),
                      )
                    else ...[
                      FTextField.password(
                        control: .managed(controller: _codeController),
                        label: Text(
                          _isPasswordType
                              ? t.common.password
                              : t.title.verification_code,
                        ),
                        hint: t.notice.ver_code_hint,
                      ),
                      if (_isDynamicCodeType)
                        FButton(
                          variant: .secondary,
                          onPress: (_sending || _countdown != null)
                              ? null
                              : _sendCode,
                          suffix: (_countdown != null)
                              ? Text(' (${_countdown}s)')
                              : null,
                          child: Text(t.action.send_sms_code),
                        ),
                    ],
                    const FDivider(),
                    const SizedBox(height: 8),
                    FButton(
                      variant: .primary,
                      onPress: (supported) ? _submit : null,
                      child: Text(t.notice.confirm),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
