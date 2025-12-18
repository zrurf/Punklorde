import 'package:punklorde/common/models/location.dart';
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

// 虚拟位置信息
final virtualRunning = signal<bool>(false); // 运行状态
final virtualCoordinate = signal<CoordinateType>(.GCJ02); // 坐标类型
final virtualLat = signal<double>(0); // 纬度
final virtualLng = signal<double>(0); // 经度
final virtualAlt = signal<double>(0); // 海拔

final virtualSpeed = signal<double>(0); // 速度
final virtualCourse = signal<double>(0); // 航向
final virtualAddress = signal<String?>(null); // 地址

// 导出的位置信息
final Computed<bool> exportRunning = computed(() {
  return rawRunning.value || virtualRunning.value;
}); // 运行状态
final Computed<CoordinateType> exportCoordinate = computed(() {
  return virtualRunning.value ? virtualCoordinate.value : rawCoordinate.value;
}); // 坐标类型
final Computed<double> exportLat = computed(() {
  return virtualRunning.value ? virtualLat.value : rawLat.value;
}); // 纬度
final Computed<double> exportLng = computed(() {
  return virtualRunning.value ? virtualLng.value : rawLng.value;
}); // 经度
final Computed<double> exportAlt = computed(() {
  return virtualRunning.value ? virtualAlt.value : rawAlt.value;
}); // 海拔
final Computed<double> exportSpeed = computed(() {
  return virtualRunning.value ? virtualSpeed.value : rawSpeed.value;
}); // 速度
final Computed<double> exportCourse = computed(() {
  return virtualRunning.value ? virtualCourse.value : rawCourse.value;
}); // 航向
final Computed<String?> exportAddress = computed(() {
  return virtualRunning.value ? virtualAddress.value : rawAddress.value;
}); // 地址
