import 'package:punklorde/common/model/theme.dart';
import 'package:punklorde/core/registry/school.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:signals/signals_flutter.dart';

// 当前学校
final Signal<School?> currentSchoolSignal = signal<School?>(null);

// 使用安全存储（未使用）
final Signal<bool> useSafeStorage = signal(false);

// 主题
final Signal<ThemeMode> themeModeSignal = signal(.system);

// 语言（null = 跟随系统）
final Signal<String?> localeSignal = signal<String?>(null);

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

/// AppLocale 的原始标识（en / zh_CN）
String localeRawCode(AppLocale locale) {
  final country = locale.countryCode;
  return (country == null || country.isEmpty)
      ? locale.languageCode
      : '${locale.languageCode}_$country';
}

/// 根据标识查找 AppLocale，找不到返回 null
AppLocale? localeByRawCode(String code) {
  for (final locale in AppLocale.values) {
    if (localeRawCode(locale) == code) return locale;
  }
  return null;
}

// 切换语言（null = 跟随系统）
void setLocale(String? code) {
  localeSignal.value = code;
  if (code == null) {
    LocaleSettings.useDeviceLocale();
    return;
  }
  final locale = localeByRawCode(code);
  if (locale != null) {
    LocaleSettings.setLocaleRaw(localeRawCode(locale));
  }
}

// 应用持久化的语言设置（main 启动时调用）
void applyStoredLocale() {
  final code = localeSignal.value;
  if (code == null) {
    LocaleSettings.useDeviceLocale();
  } else {
    final locale = localeByRawCode(code);
    if (locale != null) {
      LocaleSettings.setLocaleRaw(localeRawCode(locale));
    }
  }
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
  // 语言
  final locale = localeSignal.value;
  if (locale == null) {
    storage.remove('locale', instance: defaultMMKV);
  } else {
    storage.putString('locale', locale, instance: defaultMMKV);
  }
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

  // 加载语言
  localeSignal.value = storage.getString('locale', instance: defaultMMKV);
}
