import 'package:dio/dio.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/network/interceptor/cqupt.dart';
import 'package:punklorde/module/school/cqupt/api/endpoint.dart';
import 'package:punklorde/module/school/cqupt/model/student.dart';
import 'package:punklorde/module/school/cqupt/utils/schedule_parser.dart';
import 'package:punklorde/utils/ua.dart';

class CquptApiClient {
  late final Dio _dio;

  CquptApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )..interceptors.add(CquptForwardInterceptor());
  }

  /// 获取课表
  Future<String?> getSchedule(String studentId) async {
    try {
      final resp = await _dio.get(
        apiSchedule(studentId),
        options: Options(headers: {"User-Agent": UAUtil.getUA(.raw)}),
      );
      if (resp.statusCode != 200 || resp.data == null || resp.data is! String) {
        return null;
      }
      return resp.data as String;
    } catch (e) {
      return null;
    }
  }

  /// 获取考试信息
  Future<String?> getExam(String studentId) async {
    try {
      final resp = await _dio.get(
        apiExam(studentId),
        options: Options(headers: {"User-Agent": UAUtil.getUA(.raw)}),
      );
      if (resp.statusCode != 200 || resp.data == null || resp.data is! String) {
        return null;
      }
      return resp.data as String;
    } catch (e) {
      return null;
    }
  }

  /// 获取选课学生名单
  Future<List<StudentInfo>?> getStudentList(
    String classId,
    AuthCredential credential,
  ) async {
    try {
      final resp = await _dio.get(
        apiClassStudentList(classId),
        options: Options(
          headers: {
            "User-Agent": UAUtil.getUA(.raw),
            "Cookie": "PHPSESSID=${credential.token}",
          },
        ),
      );
      if (resp.statusCode != 200 ||
          resp.data == null ||
          resp.data is! String ||
          !(resp.data as String).contains("<body>")) {
        return null;
      }
      return parseStudentListHtml(resp.data as String);
    } catch (e) {
      return null;
    }
  }
}
