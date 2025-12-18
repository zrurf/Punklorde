import 'package:signals/signals.dart';

final rawHeadingRunning = signal<bool>(false);
final rawHeading = signal<double>(0); // 原始设备朝向

final virtualHeadingRunning = signal<bool>(false);
final virtualHeading = signal<double>(0); // 虚拟设备朝向

final Computed<bool> exportHeadingRunning = computed(() {
  return rawHeadingRunning.value || virtualHeadingRunning.value;
}); // 输出设备朝向运行状态

final Computed<double> exportHeading = computed(() {
  return virtualHeadingRunning.value ? virtualHeading.value : rawHeading.value;
}); // 输出设备朝向
