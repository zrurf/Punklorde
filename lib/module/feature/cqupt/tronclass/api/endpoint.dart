const String baseUrl = "http://lms.tc.cqupt.edu.cn";
const String apiGetEvent =
    "$baseUrl/api/radar/rollcalls?api_version=1.1.0"; // 获取签到事件
String apiCheckinQr(String id) =>
    "$baseUrl/api/rollcall/$id/answer_qr_rollcall"; // 扫码签到接口
String apiCheckinPin(String id) =>
    "$baseUrl/api/rollcall/$id/answer_number_rollcall"; // 数字签到接口
String apiCheckinRadar(String id) =>
    "$baseUrl/api/rollcall/$id/answer"; // 雷达签到接口
