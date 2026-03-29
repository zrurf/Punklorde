const String baseUrl = "https://sport.cqupt.edu.cn/new_wxapp";
const String basePortalUrl = "http://172.20.2.228";

// 登录接口
String apiLogin(String openid, String deviceType) =>
    "$baseUrl/wxUnifyId/checkBinding?wxCode=&openid=$openid&phoneType=$deviceType";

// 用户信息接口
String apiUserInfo() => "$baseUrl/wxUnifyId/getUser";

// 用户信息接口（无鉴权）
String apiUserInfoNoAuth(String unifyId) =>
    "$baseUrl/wxUnifyId/getUserInfo?unifyId=$unifyId&studentNo=1";

// 获取学期接口
String apiUtilTerm() => "$baseUrl/yearTerm/list";

// 获取跑步配置
String apiSportConfig() => "$baseUrl/setting/getRule";

// 获取运动场地接口
String apiSportPlayground() => "$baseUrl/place/getPlayground";

// 获取运动区域接口
String apiSportArea() => "$baseUrl/area/getAllArea";

// 获取运动功能接口
String apiSportFunc() => "$baseUrl/areaFunc/getFunc";

// 运动开始接口
String apiSportStart() => "$baseUrl/sportRecord/sport/start2";

// 运动结束接口
String apiSportEnd(String sportId) => "$baseUrl/sportRecord/sport/end/$sportId";

// 运动继续接口
String apiSportContinue(String sportId) =>
    "$baseUrl/sportRecord/sport/continue/$sportId";

// 运动信息接口
String apiSportInfo(String sportId) => "$baseUrl/sportRecord/info/$sportId";

// 运动数据上传接口
String apiSportUpload() => "$baseUrl/sportRecord/point/saveListByNo";

// 重试上传运动数据接口
String apiSportUploadRetry() => "$baseUrl/sportRecord/point/uploadPoints";

// 获取运动轨迹接口
String apiSportGetPoints(String sportId) =>
    "$baseUrl/sportPoint/listAll/$sportId";

// 获取运动记录接口
String apiSportGetRecords() => "$baseUrl/sportsResult/list";

// 获取运动统计接口
String apiSportStat() => "$basePortalUrl/api/sunlight/mobile/statistics";
