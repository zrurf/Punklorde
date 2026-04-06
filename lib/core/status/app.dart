import 'package:punklorde/common/model/theme.dart';
import 'package:punklorde/core/registry/school.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:signals/signals_flutter.dart';

// 当前学校
final Signal<School?> currentSchoolSignal = signal<School?>(null);

// 使用安全存储（未使用）
final Signal<bool> useSafeStorage = signal(false);

// 主题
final Signal<ThemeMode> themeModeSignal = signal(.system);

// 设置当前学校
void setCurrentSchool(School? school) {
  currentSchoolSignal.value = school;
}

void setCurrentSchoolById(String schoolId) {
  setCurrentSchool(getSchool(schoolId));
}

// 循环主题
void cycleThemeMode() {
  themeModeSignal.value = switch (themeModeSignal.value) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
}

// 初始化应用状态
void initAppStatus() {
  effect(() {
    storeAppStatus();
  });
}

// 存储层
void storeAppStatus() {
  final storage = StorageService();
  // 学校
  if (currentSchoolSignal.value != null) {
    storage.putString(
      'school',
      currentSchoolSignal.value!.id,
      instance: defaultMMKV,
    );
  }
  // 主题
  storage.putInt('theme', themeModeSignal.value.index, instance: defaultMMKV);
}

void loadAppStatus() {
  final storage = StorageService();

  // 加载主题
  themeModeSignal.value =
      ThemeMode.values[storage.getInt('theme', instance: defaultMMKV)];

  // 加载学校
  final schoolId = storage.getString('school', instance: defaultMMKV);
  if (schoolId != null && isSchoolExist(schoolId)) {
    setCurrentSchool(getSchool(schoolId));
  }
}
