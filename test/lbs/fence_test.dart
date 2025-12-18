import 'package:flutter_test/flutter_test.dart';
import "dart:math";

import 'package:punklorde/common/utils/lbs/fence.dart';

void main() {
  group('凸多边形点包含测试 - 叉积法', () {
    final square = [Point(0, 0), Point(4, 0), Point(4, 4), Point(0, 4)];

    test('点在凸多边形内部', () {
      expect(isPointInPolygon(Point(2, 2), square), isTrue);
      expect(isPointInPolygon(Point(1, 1), square), isTrue);
      expect(isPointInPolygon(Point(3.9, 3.9), square), isTrue);
    });

    test('点在凸多边形外部', () {
      expect(isPointInPolygon(Point(5, 5), square), isFalse);
      expect(isPointInPolygon(Point(-1, 2), square), isFalse);
      expect(isPointInPolygon(Point(2, 5), square), isFalse);
    });

    test('点在凸多边形边上', () {
      expect(isPointInPolygon(Point(2, 0), square), isTrue);
      expect(isPointInPolygon(Point(4, 2), square), isTrue);
      expect(isPointInPolygon(Point(0, 3), square), isTrue);
    });

    test('点在凸多边形顶点', () {
      expect(isPointInPolygon(Point(0, 0), square), isTrue);
      expect(isPointInPolygon(Point(4, 4), square), isTrue);
    });

    test('三角形内的点', () {
      final triangle = [Point(0, 0), Point(4, 0), Point(2, 4)];
      expect(isPointInPolygon(Point(2, 1), triangle), isTrue);
      expect(isPointInPolygon(Point(1, 0.5), triangle), isTrue);
      expect(isPointInPolygon(Point(3, 0.5), triangle), isTrue);
    });
  });

  group('凹多边形点包含测试 - 射线法', () {
    final lShape = [
      Point(0, 0),
      Point(4, 0),
      Point(4, 2),
      Point(2, 2),
      Point(2, 4),
      Point(0, 4),
    ];

    test('点在凹多边形内部', () {
      expect(isPointInPolygon(Point(1, 1), lShape), isTrue);
      expect(isPointInPolygon(Point(3, 1), lShape), isTrue);
      expect(isPointInPolygon(Point(1, 3), lShape), isTrue);
    });

    test('点在凹多边形外部', () {
      expect(isPointInPolygon(Point(3, 3), lShape), isFalse);
      expect(isPointInPolygon(Point(5, 1), lShape), isFalse);
      expect(isPointInPolygon(Point(1, 5), lShape), isFalse);
    });

    test('点在凹多边形边上', () {
      expect(isPointInPolygon(Point(2, 0), lShape), isTrue);
      expect(isPointInPolygon(Point(4, 1), lShape), isTrue);
      expect(isPointInPolygon(Point(1, 4), lShape), isTrue);
    });

    test('复杂凹多边形', () {
      final complexShape = [
        Point(0, 0),
        Point(6, 0),
        Point(6, 2),
        Point(4, 2),
        Point(4, 4),
        Point(6, 4),
        Point(6, 6),
        Point(0, 6),
      ];

      expect(isPointInPolygon(Point(1, 1), complexShape), isTrue);
      expect(isPointInPolygon(Point(5, 1), complexShape), isTrue);
      expect(isPointInPolygon(Point(5, 3), complexShape), isFalse); // 在凹口内
      expect(isPointInPolygon(Point(5, 5), complexShape), isTrue);
    });
  });

  group('算法自动选择测试', () {
    test('自动选择凸多边形算法', () {
      final convexPolygon = [
        Point(0, 0),
        Point(3, 0),
        Point(3, 3),
        Point(0, 3),
      ];

      // 这个应该使用凸多边形算法
      expect(isPointInPolygon(Point(1, 1), convexPolygon), isTrue);
    });

    test('自动选择凹多边形算法', () {
      final concavePolygon = [
        Point(0, 0),
        Point(4, 0),
        Point(4, 2),
        Point(2, 2),
        Point(2, 4),
        Point(0, 4),
      ];

      // 这个应该使用凹多边形算法
      expect(isPointInPolygon(Point(1, 1), concavePolygon), isTrue);
    });
  });

  group('边界情况测试', () {
    test('浮点数精度处理', () {
      final polygon = [Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1)];

      // 接近边界的点
      expect(isPointInPolygon(Point(0.0000001, 0.0000001), polygon), isTrue);
      expect(isPointInPolygon(Point(0.9999999, 0.9999999), polygon), isTrue);
      expect(isPointInPolygon(Point(1.0000001, 0.5), polygon), isFalse);
    });

    test('水平线和垂直线', () {
      final polygon = [Point(0, 0), Point(0, 3), Point(3, 3), Point(3, 0)];

      expect(isPointInPolygon(Point(1, 0), polygon), isTrue);
      expect(isPointInPolygon(Point(0, 2), polygon), isTrue);
      expect(isPointInPolygon(Point(3, 1), polygon), isTrue);
    });
  });

  group('缠绕方向测试', () {
    test('顺时针多边形', () {
      final clockwisePolygon = [
        Point(0, 0),
        Point(4, 0),
        Point(4, 4),
        Point(0, 4),
      ];

      expect(isPointInPolygon(Point(2, 2), clockwisePolygon), isTrue);
    });

    test('逆时针多边形', () {
      final counterClockwisePolygon = [
        Point(0, 0),
        Point(0, 4),
        Point(4, 4),
        Point(4, 0),
      ];

      expect(isPointInPolygon(Point(2, 2), counterClockwisePolygon), isTrue);
    });
  });
}
