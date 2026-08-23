/// 畅课 TronClass 签到参数解码工具
class TronClassSignDecoder {
  TronClassSignDecoder._();

  /// 特殊字符定义
  static final String ta = String.fromCharCode(30); // \x1e
  static final String ea = String.fromCharCode(31); // \x1f
  static final String na = String.fromCharCode(26); // \x1a
  static final String ra = String.fromCharCode(16); // \x10

  static final String ia = '${na}1'; // true
  static final String oa = '${na}0'; // false

  /// 字段名 -> 短编码（aa）
  static const List<String> _aaKeys = [
    'courseId',
    'activityId',
    'activityType',
    'data',
    'rollcallId',
    'groupSetId',
    'accessCode',
    'action',
    'enableGroupRollcall',
    'createUser',
    'joinCourse',
  ];

  /// 字段名 -> 特殊编码（ua，用于 activityType 的几个枚举值）
  static const List<String> _uaKeys = ['classroom-exam', 'feedback', 'vote'];

  /// aa: 字段名 -> 短编码（base36 下标）
  static final Map<String, String> aa = Map.unmodifiable({
    for (var e in _aaKeys.asMap().entries) e.value: _toBase36(e.key),
  });

  /// ua: 字段名 -> na + base36(index+2)
  static final Map<String, String> ua = Map.unmodifiable({
    for (var e in _uaKeys.asMap().entries) e.value: na + _toBase36(e.key + 2),
  });

  /// ca: aa 的反向映射，短编码 -> 字段名
  static final Map<String, String> ca = {
    for (var e in aa.entries) e.value: e.key,
  };

  /// sa: ua 的反向映射，特殊编码 -> 字段名
  static final Map<String, String> sa = {
    for (var e in ua.entries) e.value: e.key,
  };

  /// 将 [raw] 解码为 `Map<String, dynamic>?`。
  /// - 如果 [raw] 为空或不是字符串，返回 `null`。
  /// - 如果解析失败，返回 `null`（不会抛出异常）。
  static Map<String, dynamic>? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _parseSignQrCode(raw);
  }

  /// 将 URL 中 p 参数或完整字符串解析为 Map。
  static Map<String, dynamic>? _parseSignQrCode(String t) {
    final result = <String, dynamic>{};

    // 先按 "!" 分段，过滤掉空段
    final parts = t.split('!').where((s) => s.isNotEmpty);
    for (var part in parts) {
      // 只按第一个 "~" 分割，避免破坏后面可能存在的 "~"
      final splitted = part.split('~');
      if (splitted.length < 2) continue;

      final rawKey = splitted[0];
      final rawValue = splitted.sublist(1).join('~'); // 还原内部 "~"

      // key 映射：ca 有则用短编码对应的字段名，否则保持原样
      final key = ca[rawKey] ?? rawKey;

      dynamic value;
      try {
        value = _decodeValue(rawValue);
      } catch (_) {
        // 解析失败时保留原始字符串
        value = rawValue;
      }

      result[key] = value;
    }

    return result.isEmpty ? null : result;
  }

  /// 解码一个值（对应 Python/JS 里的 value 处理逻辑）
  static dynamic _decodeValue(String raw) {
    // 1. 以 na 开头：布尔或特殊枚举
    if (raw.startsWith(na)) {
      if (raw == ia) return true;
      if (raw == oa) return false;
      // 其它 na 开头：尝试用 sa 映射，没有则保留原串
      return sa[raw] ?? raw;
    }

    // 2. 以 ra 开头：可能是整数或浮点数（base36 编码）
    if (raw.startsWith(ra)) {
      final withoutPrefix = raw.substring(1);
      final parts = withoutPrefix.split('.');

      // 对每个部分尝试 base36 解析
      final nums = <int>[];
      for (var p in parts) {
        final v = int.tryParse(p, radix: 36);
        if (v == null) {
          // 只要有一段不是合法 base36，就放弃数字解析，直接返回原串
          return raw;
        }
        nums.add(v);
      }

      if (nums.isEmpty) return raw;
      if (nums.length == 1) return nums.first;

      // 多段：按 Python 逻辑只取前两段组成浮点数
      return double.tryParse('${nums[0]}.${nums[1]}') ??
          '${nums[0]}.${nums[1]}';
    }

    // 3. 其它情况：替换转义字符
    return raw.replaceAll(ea, '~').replaceAll(ta, '!');
  }

  /// 整数转 base36（与仓库里的 to_base36 行为一致，包括负数）
  static String _toBase36(int num) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    if (num < 0) return '-${_toBase36(-num)}';
    if (num < 36) return chars[num];

    var n = num;
    var result = '';
    while (n > 0) {
      final rem = n % 36;
      n = n ~/ 36;
      result = chars[rem] + result;
    }
    return result;
  }
}
