const String mobileBaseUrl = "https://mobilelearn.chaoxing.com";
const String moocBaseUrl = "https://mooc1-api.chaoxing.com";
const String cloudDiskBaseUrl = "https://pan-yz.chaoxing.com";

/// 课程列表接口
const String apiCourseList = "$moocBaseUrl/mycourse/backclazzdata?view=json";

/// 活动列表接口
String apiActiveList(String courseId, String classId) =>
    "$mobileBaseUrl/v2/apis/active/student/activelist?courseId=$courseId&classId=$classId&fid=0&showNotStartedActive=0";

// ==== 签到接口 ====
/// 签到事件详情
String apiSignDetail(String activeId) =>
    "$mobileBaseUrl/newsign/signDetail?type=1&activePrimaryId=$activeId";

/// 签到接口
const String apiCommonSign = "$mobileBaseUrl/pptSign/stuSignajax";

/// 签到结果接口
String apiSignResult(String activeId) =>
    "$mobileBaseUrl/v2/apis/sign/getAttendInfo?activeId=$activeId&moreClassAttendEnc=";

/// 签到码校验接口
String apiSignCodeCheck(String activeId, String code) =>
    "$mobileBaseUrl/widget/sign/pcStuSignController/checkSignCode?activeId=$activeId&signCode=$code";
