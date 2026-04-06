/// 教务在线数据接口
const String baseApApiUrl = "http://jwzx.cqupt.edu.cn";

/// 课表接口
String apiSchedule(String studentId) =>
    "$baseApApiUrl/kebiao/kb_stu.php?xh=$studentId";

/// 选课学生名单接口
String apiClassStudentList(String classId) =>
    "$baseApApiUrl/kebiao/kb_stuList.php?jxb=$classId";

/// 考试接口
String apiExam(String studentId) =>
    "$baseApApiUrl/ksap/showKsap.php?type=stu&id=$studentId";

/// 补考接口
String apiMakeUpExam(String studentId) =>
    "$baseApApiUrl/ksap/ksapSearch.php?searchType=stuBk&key=$studentId";
