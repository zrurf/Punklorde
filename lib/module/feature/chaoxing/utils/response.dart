import 'dart:convert';

import 'package:punklorde/module/feature/chaoxing/model/common.dart';

/// API 响应解析工具
class ActiveResponseParser {
  /// 从完整响应 JSON 中提取活动列表
  static List<ActiveResult> parseListFromResponse(
    Map<String, dynamic> response,
  ) {
    // 检查 result 是否为成功状态（通常 1 表示成功）
    final result = response['result'];
    if (result != 1) {
      return [];
    }

    final data = response['data'];
    if (data == null || data is! Map<String, dynamic>) {
      return [];
    }

    final activeList = data['activeList'];
    if (activeList == null || activeList is! List) {
      return [];
    }

    return activeList
        .whereType<Map<String, dynamic>>() // 过滤非 Map 项
        .map((item) => ActiveResult.fromJson(item))
        .toList();
  }

  /// 从原始 JSON 字符串解析活动列表
  static List<ActiveResult> parseListFromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> response = json.decode(jsonString);
      return parseListFromResponse(response);
    } catch (e) {
      // JSON 解析失败
      return [];
    }
  }
}
