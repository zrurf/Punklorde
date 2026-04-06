const String epBaseCalendar = "data/Calendar"; // 日程数据基础端点
const String epCalendarIndex = "$epBaseCalendar/index.json"; // 学期索引
String epCalendarSemester(String school, String semester) =>
    "$epBaseCalendar/$school/$semester.semester.json"; // 学期安排端点
