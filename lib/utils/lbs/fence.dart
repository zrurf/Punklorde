import "dart:math";

num _crossProduct(Point a, Point b, Point c) {
  return (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
}

// 凸多边形检测
bool _isConvexPolygen(List<Point> points) {
  int n = points.length;

  if (n < 3) return false;

  num sign = 0;

  for (int i = 0; i < n; i++) {
    num crossProduct = _crossProduct(
      points[i],
      points[(i + 1) % n],
      points[(i + 2) % n],
    );

    if (i == 0) {
      sign = crossProduct.sign;
    } else if (crossProduct.sign != sign) {
      return false;
    } else {
      sign = crossProduct.sign;
    }
  }
  return true;
}

bool _ispointsClockwise(List<Point> points) {
  double area = 0;
  int n = points.length;

  for (int i = 0; i < n; i++) {
    Point a = points[i];
    Point b = points[(i + 1) % n];
    area += (b.x - a.x) * (b.y + a.y);
  }

  return area > 0;
}

//
bool _isPointOnEdge(Point point, Point a, Point b) {
  // 检查点是否在线段的边界框内
  if (point.x < min(a.x, b.x) - 1e-10 ||
      point.x > max(a.x, b.x) + 1e-10 ||
      point.y < min(a.y, b.y) - 1e-10 ||
      point.y > max(a.y, b.y) + 1e-10) {
    return false;
  }

  // 检查三点共线且在线段上
  num crossProduct =
      (point.x - a.x) * (b.y - a.y) - (point.y - a.y) * (b.x - a.x);

  if (crossProduct.abs() > 1e-10) {
    return false;
  }

  // 计算点在线段上的参数t
  double t;
  if ((b.x - a.x).abs() > (b.y - a.y).abs()) {
    t = (point.x - a.x) / (b.x - a.x);
  } else {
    t = (point.y - a.y) / (b.y - a.y);
  }

  // t应该在[0,1]范围内，考虑浮点误差
  return t >= -1e-10 && t <= 1 + 1e-10;
}

bool _rayCrossesSegment(Point point, Point a, Point b) {
  // 排除水平线段和点在线上方/下方的情况
  if ((a.y > point.y && b.y > point.y) ||
      (a.y < point.y && b.y < point.y) ||
      (a.y == b.y)) {
    return false;
  }

  // 确保a在b下方
  if (a.y > b.y) {
    Point temp = a;
    a = b;
    b = temp;
  }

  // 计算交点x坐标
  double xIntersect = a.x + (point.y - a.y) * (b.x - a.x) / (b.y - a.y);

  // 交点必须在点右侧
  return xIntersect > point.x;
}

bool _rayCasting(Point point, List<Point> points) {
  int n = points.length;
  int count = 0;

  for (int i = 0; i < n; i++) {
    Point a = points[i];
    Point b = points[(i + 1) % n];

    // 检查点是否在边上
    if (_isPointOnEdge(point, a, b)) {
      return true;
    }

    // 检查射线与边的交点
    if (_rayCrossesSegment(point, a, b)) {
      count++;
    }
  }

  // 交点为奇数表示在多边形内
  return count % 2 == 1;
}

bool _isPointInConvex(Point point, List<Point> points) {
  int n = points.length;

  // 确定多边形的缠绕方向（顺时针或逆时针）
  bool isClockwise = _ispointsClockwise(points);

  for (int i = 0; i < n; i++) {
    Point a = points[i];
    Point b = points[(i + 1) % n];

    num crossProduct = _crossProduct(a, b, point);

    // 对于顺时针多边形，点应该在所有边的右侧（叉积 <= 0）
    // 对于逆时针多边形，点应该在所有边的左侧（叉积 >= 0）
    if (isClockwise) {
      if (crossProduct > 0) return false; // 点在边的左侧，不在多边形内
    } else {
      if (crossProduct < 0) return false; // 点在边的右侧，不在多边形内
    }

    // 如果点在边上，直接返回true
    if (crossProduct.abs() < 1e-10 && _isPointOnEdge(point, a, b)) {
      return true;
    }
  }

  return true;
}

bool isPointInPolygon(Point point, List<Point> points) {
  if (points.length < 3) return false;
  return (_isConvexPolygen(points))
      ? _isPointInConvex(point, points)
      : _rayCasting(point, points);
}
