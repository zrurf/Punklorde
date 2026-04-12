import 'package:intl/intl.dart';

final _format = DateFormat("yyyy-MM-dd HH:mm:ss");

// 时间格式化
// 手写字符串拼接性能优于intl的格式化
String formatDate(DateTime date) {
  return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} '
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}:${_twoDigits(date.second)}';
}

/// 将字符串解析为 DateTime
DateTime parseDate(String str) {
  return _format.parse(str);
}

// 两位数填充
String _twoDigits(int n) {
  if (n >= 10) return '$n';
  return '0$n';
}

// 文件名时间格式化
String formatFileNameDate(DateTime date) {
  return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}_'
      '${_twoDigits(date.hour)}_${_twoDigits(date.minute)}_${_twoDigits(date.second)}';
}

// 时长格式化
String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  } else {
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}

/// 开始分钟数转时间
String formatDayMinutes(int minutes) {
  final d = Duration(minutes: minutes);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}';
}

/// 格式化周数列表
///
/// 将周数列表格式化为易读的字符串。
/// 例如：[1, 2, 3, 4] -> "1-4周"，[1, 2, 3, 5] -> "1-3周,5周"
String formatWeeks(List<int> weeks) {
  if (weeks.isEmpty) return '';

  // 去重并排序
  final sortedWeeks = weeks.toSet().toList()..sort();

  final buffer = StringBuffer();
  int rangeStart = sortedWeeks[0];
  int prev = sortedWeeks[0];

  // 辅助函数：写入一个区间或单点
  void writeRange(int start, int end) {
    if (buffer.isNotEmpty) {
      buffer.write(',');
    }
    if (start == end) {
      buffer.write('$start周');
    } else {
      buffer.write('$start-$end周');
    }
  }

  for (int i = 1; i < sortedWeeks.length; i++) {
    final current = sortedWeeks[i];
    // 如果当前周数是前一个周数的后继，则继续扩展区间
    if (current == prev + 1) {
      prev = current;
    } else {
      // 否则，结束当前区间并开始新区间
      writeRange(rangeStart, prev);
      rangeStart = current;
      prev = current;
    }
  }

  // 写入最后一个区间
  writeRange(rangeStart, prev);

  return buffer.toString();
}
