/// 时间段
class TimePeriod {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  TimePeriod({required this.start, required this.end})
    : duration = end.difference(start);
}
