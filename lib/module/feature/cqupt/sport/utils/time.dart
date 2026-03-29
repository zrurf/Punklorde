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

// 时长格式化
String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  } else {
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}

/// 根据速度计算配速
/// [speedInMetersPerSecond] 速度，单位：米/秒
/// 返回格式化字符串，如：5'30"
String formatPace(double speedInMetersPerSecond) {
  if (speedInMetersPerSecond <= 0) {
    return "--′--″";
  }

  double totalSeconds = 1000 / speedInMetersPerSecond;

  int minutes = totalSeconds ~/ 60; // 取整分钟
  int seconds = (totalSeconds % 60).round(); // 取余下的秒数（四舍五入）

  String secondsStr = seconds.toString().padLeft(2, '0');

  return "$minutes′$secondsStr″";
}
