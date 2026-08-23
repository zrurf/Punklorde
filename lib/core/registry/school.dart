import 'package:punklorde/module/model/school.dart';
import 'package:punklorde/module/school/cqupt/manifest.dart';
import 'package:punklorde/module/school/cuc/manifest.dart';

final Map<String, School> schoolsRegistry = {
  schoolCqupt.id.toLowerCase(): schoolCqupt, // CQUPT 重庆邮电大学
  schoolCuc.id.toLowerCase(): schoolCuc, // CUC 中国传媒大学
};

School? getSchool(String id) {
  return schoolsRegistry[id.toLowerCase()];
}

bool isSchoolExist(String id) {
  return schoolsRegistry.containsKey(id.toLowerCase());
}

List<School> getSchools() {
  return schoolsRegistry.values.toList();
}
