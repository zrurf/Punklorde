import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:signals/signals_flutter.dart';

/// 实验性功能定义
class ExperimentFeature {
  final String id;
  final String name;
  final String desc;

  const ExperimentFeature({
    required this.id,
    required this.name,
    required this.desc,
  });
}

/// 畅课跨课程签到：使用任意课程的二维码 data 为本课程签到记录上报
const experimentCrossCourseCheckin = ExperimentFeature(
  id: 'tronclass_cross_course_checkin',
  name: '畅课跨课程签到',
  desc: '使用任意课程二维码为本课程签到',
);

/// 实验性功能注册表
final List<ExperimentFeature> experimentFeatures = const [
  experimentCrossCourseCheckin,
];

/// 已启用的实验性功能ID集合
final Signal<Set<String>> experimentEnabledSignal = Signal({});

/// 实验性功能是否启用
bool isExperimentEnabled(String id) =>
    experimentEnabledSignal.value.contains(id);

/// 切换实验性功能状态
void setExperimentEnabled(String id, bool enabled) {
  if (enabled) {
    experimentEnabledSignal.value = {...experimentEnabledSignal.value, id};
  } else {
    experimentEnabledSignal.value = {...experimentEnabledSignal.value}
      ..remove(id);
  }
}

/// 订阅信号变化自动持久化
void initExperimentStatus() {
  effect(() {
    storeExperimentStatus();
  });
}

Future<void> storeExperimentStatus() async {
  await StorageService().putList(
    '_experiments',
    experimentEnabledSignal.value.toList(),
    instance: defaultMMKV,
  );
}

/// 加载实验性功能状态
Future<void> loadExperimentStatus() async {
  final list = await StorageService().getList(
    '_experiments',
    instance: defaultMMKV,
  );
  if (list == null) return;
  experimentEnabledSignal.value = list.cast<String>().toSet();
}
