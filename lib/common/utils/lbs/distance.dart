import 'dart:math';

double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const double R = 6371000.0; // WGS-84地球平均半径（米）
  const double degToRad = pi / 180.0; // 缓存转换因子

  // 相同坐标直接返回0
  if (lat1 == lat2 && lng1 == lng2) return 0.0;

  // 一次性转换为弧度
  final double radLat1 = lat1 * degToRad;
  final double radLat2 = lat2 * degToRad;
  final double deltaLat = (lat2 - lat1) * degToRad;
  final double deltaLng = (lng2 - lng1) * degToRad;

  // 缓存半角正弦值，避免重复计算
  final double sinHalfDeltaLat = sin(deltaLat * 0.5);
  final double sinHalfDeltaLng = sin(deltaLng * 0.5);

  final double a =
      sinHalfDeltaLat * sinHalfDeltaLat +
      cos(radLat1) * cos(radLat2) * sinHalfDeltaLng * sinHalfDeltaLng;

  final double c = 2.0 * asin(sqrt(a > 1.0 ? 1.0 : a));
  return R * c;
}
