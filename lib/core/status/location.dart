import 'package:punklorde/common/model/location.dart';
import 'package:signals/signals.dart';

// 原始位置信息
final rawRunning = signal<bool>(false); // 运行状态
final rawCoordinate = signal<CoordinateType>(.GCJ02); // 坐标类型
final rawLat = signal<double>(0); // 纬度
final rawLng = signal<double>(0); // 经度
final rawAlt = signal<double>(0); // 海拔

final rawSpeed = signal<double>(0); // 速度
final rawCourse = signal<double>(0); // 航向
final rawAddress = signal<String?>(null); // 地址
