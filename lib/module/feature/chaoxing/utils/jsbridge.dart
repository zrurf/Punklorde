import 'dart:convert';

/// 解析结果
class JsBridgeData {
  final String action;
  final dynamic data; // 已解码的 JSON，可能为 null

  JsBridgeData({required this.action, this.data});

  @override
  String toString() => 'JsBridgeData(action: $action, data: $data)';
}

class JsBridgeUtil {
  // 匹配 jsbridge://<action>?<query> 格式
  static final RegExp _protocolRegex = RegExp(
    r'^jsbridge://([^?]+)(?:\?(.*))?$',
    caseSensitive: true, // 确保 action 大小写敏感
  );

  /// 判断并解析 jsbridge 协议
  /// 返回 null 表示不是 jsbridge 请求
  static JsBridgeData? parsePrompt(String promptMessage) {
    if (promptMessage.isEmpty) return null;

    final match = _protocolRegex.firstMatch(promptMessage);
    if (match == null) return null;

    // 提取 action，保留原始大小写
    final String action = match.group(1)!;
    if (action.isEmpty) return null; // 无效格式

    // 提取查询字符串部分
    final String? queryString = match.group(2);

    // 解析 data 参数
    dynamic data;
    if (queryString != null && queryString.isNotEmpty) {
      // 使用 Uri.splitQueryString 安全解析参数
      final Map<String, String> params = Uri.splitQueryString(queryString);
      final String? encodedData = params['data'];
      if (encodedData != null && encodedData.isNotEmpty) {
        try {
          final String decodedJson = Uri.decodeComponent(encodedData);
          data = json.decode(decodedJson);
        } catch (_) {
          // 解析失败时 data 为 null，避免崩溃
          data = null;
        }
      }
    }

    return JsBridgeData(action: action, data: data);
  }
}
