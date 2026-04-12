enum ActiveType {
  unknown,
  signIn, // 签到(2)
  signOut, // 签退(74)
  scheduledSignIn, // 定时签到(54)
}

/// 课程数据模型
class CourseData {
  final int id; // 必需
  final String name; // 必需
  final String teacher; // 原 teacherfactor，必需（视业务而定，此处设为可空）
  final int state; // 原 coursestate，必需
  final String schoolId; // 原 belongSchoolId，必需
  final int createTime; // 原 createtime
  final String? appInfo;
  final int? sectionId;
  final int? smartCourseState;
  final int? appData;
  final String? schools;
  final int? isCourseSquare;

  CourseData({
    required this.id,
    required this.name,
    required this.teacher,
    required this.state,
    required this.schoolId,
    required this.createTime,
    this.appInfo,
    this.sectionId,
    this.smartCourseState,
    this.appData,
    this.schools,
    this.isCourseSquare,
  });

  /// 从 JSON 创建 CourseData 实例
  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      id: json['id'] as int,
      name: json['name'] as String,
      teacher: json['teacherfactor'] as String? ?? '',
      state: json['coursestate'] as int? ?? 0,
      schoolId: json['belongSchoolId'] as String? ?? '',
      createTime: json['createtime'] as int? ?? 0,
      appInfo: json['appInfo'] as String?,
      sectionId: json['sectionId'] as int?,
      smartCourseState: json['smartCourseState'] as int?,
      appData: json['appData'] as int?,
      schools: json['schools'] as String?,
      isCourseSquare: json['isCourseSquare'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacherfactor': teacher,
      'coursestate': state,
      'belongSchoolId': schoolId,
      'createtime': createTime,
      'appInfo': appInfo,
      'sectionId': sectionId,
      'smartCourseState': smartCourseState,
      'appData': appData,
      'schools': schools,
      'isCourseSquare': isCourseSquare,
    };
  }
}

/// 班级数据模型
class ClassData {
  final int id; // 必需（来自 content.id）
  final int personalId; // 必需（来自 content.cpi）
  final String name; // 必需（来自 content.name）
  final int studentCount;
  final String? chatId;
  final int? isFiled;
  final bool? isStart;
  final int? isRetire;
  final int? state;
  final int? roleType;
  final String? bbsId;
  final int? isSquare;
  final String? beginDate;
  final String? endDate;
  final List<CourseData> courses; // 课程列表

  ClassData({
    required this.id,
    required this.personalId,
    required this.name,
    required this.studentCount,
    this.chatId,
    this.isFiled,
    this.isStart,
    this.isRetire,
    this.state,
    this.roleType,
    this.bbsId,
    this.isSquare,
    this.beginDate,
    this.endDate,
    required this.courses,
  });

  /// 从 content JSON 创建 ClassData 实例
  factory ClassData.fromContentJson(Map<String, dynamic> contentJson) {
    final courseList = <CourseData>[];
    final courseData = contentJson['course']?['data'] as List?;
    if (courseData != null) {
      for (final item in courseData) {
        courseList.add(CourseData.fromJson(item as Map<String, dynamic>));
      }
    }

    return ClassData(
      id: contentJson['id'] as int,
      personalId: contentJson['cpi'] as int,
      name: contentJson['name'] as String,
      studentCount: contentJson['studentcount'] as int? ?? 0,
      chatId: contentJson['chatid'] as String?,
      isFiled: contentJson['isFiled'] as int?,
      isStart: contentJson['isstart'] as bool?,
      isRetire: contentJson['isretire'] as int?,
      state: contentJson['state'] as int?,
      roleType: contentJson['roletype'] as int?,
      bbsId: contentJson['bbsid'] as String?,
      isSquare: contentJson['isSquare'] as int?,
      beginDate: contentJson['beginDate'] as String?,
      endDate: contentJson['endDate'] as String?,
      courses: courseList,
    );
  }

  Map<String, dynamic> toContentJson() {
    return {
      'id': id,
      'cpi': personalId,
      'name': name,
      'studentcount': studentCount,
      'chatid': chatId,
      'isFiled': isFiled,
      'isstart': isStart,
      'isretire': isRetire,
      'state': state,
      'roletype': roleType,
      'bbsid': bbsId,
      'isSquare': isSquare,
      'beginDate': beginDate,
      'endDate': endDate,
      'course': {'data': courses.map((c) => c.toJson()).toList()},
    };
  }
}

/// API 响应整体模型
class CourseResponse {
  final int result;
  final String msg;
  final List<ClassData> classes; // 过滤后的班级列表
  final String? mcode;
  final int? createcourse;
  final int? teacherEndCourse;
  final int? showEndCourse;
  final bool? hasMore;
  final int? stuEndCourse;

  CourseResponse({
    required this.result,
    required this.msg,
    required this.classes,
    this.mcode,
    this.createcourse,
    this.teacherEndCourse,
    this.showEndCourse,
    this.hasMore,
    this.stuEndCourse,
  });

  /// 从完整响应 JSON 生成 CourseResponse 对象
  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    final channelList = json['channelList'] as List? ?? [];
    final classList = <ClassData>[];

    for (final channel in channelList) {
      final cataid = channel['cataid']?.toString();
      if (cataid == '100000002') {
        final content = channel['content'] as Map<String, dynamic>?;
        if (content != null) {
          classList.add(ClassData.fromContentJson(content));
        }
      }
    }

    return CourseResponse(
      result: json['result'] as int? ?? -1,
      msg: json['msg'] as String? ?? '',
      classes: classList,
      mcode: json['mcode'] as String?,
      createcourse: json['createcourse'] as int?,
      teacherEndCourse: json['teacherEndCourse'] as int?,
      showEndCourse: json['showEndCourse'] as int?,
      hasMore: json['hasMore'] as bool?,
      stuEndCourse: json['stuEndCourse'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'msg': msg,
      'channelList': classes
          .map((c) => {'cataid': '100000002', 'content': c.toContentJson()})
          .toList(),
      'mcode': mcode,
      'createcourse': createcourse,
      'teacherEndCourse': teacherEndCourse,
      'showEndCourse': showEndCourse,
      'hasMore': hasMore,
      'stuEndCourse': stuEndCourse,
    };
  }
}

/// 活动数据模型
class ActiveResult {
  /// 活动ID
  final int id;

  /// 活动类型
  final int activeType;

  /// 标题，对应原 nameOne
  final String title;

  /// 副标题，对应原 nameTwo
  final String? subtitle;

  /// 描述，对应原 nameFour
  final String? description;

  /// 开始时间（时间戳毫秒转 DateTime）
  final DateTime? startTime;

  /// 结束时间（空字符串或无效值转为 null）
  final DateTime? endTime;

  /// 用户状态
  final int? userStatus;

  /// 其他ID
  final String? otherId;

  /// 分组ID
  final int? groupId;

  /// 来源
  final int? source;

  /// 是否查看
  final int? isLook;

  /// 类型
  final int? type;

  /// 发布数量
  final int? releaseNum;

  /// 参与数量
  final int? attendNum;

  /// 图标URL
  final String? logo;

  /// 是否旗帜标志
  final bool? flagLogo;

  /// 状态
  final int? status;

  const ActiveResult({
    required this.id,
    required this.activeType,
    required this.title,
    this.subtitle,
    this.description,
    this.startTime,
    this.endTime,
    this.userStatus,
    this.otherId,
    this.groupId,
    this.source,
    this.isLook,
    this.type,
    this.releaseNum,
    this.attendNum,
    this.logo,
    this.flagLogo,
    this.status,
  });

  /// 获取事件类型
  ActiveType get getActiveType => switch (activeType) {
    2 => .signIn,
    54 => .scheduledSignIn,
    74 => .signOut,
    _ => .unknown,
  };

  /// 从 JSON 创建 Active 对象
  factory ActiveResult.fromJson(Map<String, dynamic> json) {
    // 解析开始时间（毫秒时间戳）
    DateTime? parseStartTime(dynamic start) {
      if (start is int) {
        return DateTime.fromMillisecondsSinceEpoch(start);
      } else if (start is String && start.isNotEmpty) {
        final int? millis = int.tryParse(start);
        return millis != null
            ? DateTime.fromMillisecondsSinceEpoch(millis)
            : null;
      }
      return null;
    }

    // 解析结束时间（空字符串或无效值返回 null）
    DateTime? parseEndTime(dynamic end) {
      if (end is String && end.isEmpty) return null;
      if (end is int) return DateTime.fromMillisecondsSinceEpoch(end);
      if (end is String) {
        final int? millis = int.tryParse(end);
        return millis != null
            ? DateTime.fromMillisecondsSinceEpoch(millis)
            : null;
      }
      return null;
    }

    return ActiveResult(
      id: json['id'] as int,
      activeType: json['activeType'] as int,
      title: json['nameOne'] as String,
      subtitle: json['nameTwo'] as String?,
      description: json['nameFour'] as String?,
      startTime: parseStartTime(json['startTime']),
      endTime: parseEndTime(json['endTime']),
      userStatus: json['userStatus'] as int?,
      otherId: json['otherId'] as String?,
      groupId: json['groupId'] as int?,
      source: json['source'] as int?,
      isLook: json['isLook'] as int?,
      type: json['type'] as int?,
      releaseNum: json['releaseNum'] as int?,
      attendNum: json['attendNum'] as int?,
      logo: json['logo'] as String?,
      flagLogo: json['flagLogo'] as bool?,
      status: json['status'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activeType': activeType,
      'nameOne': title,
      'nameTwo': subtitle,
      'nameFour': description,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'userStatus': userStatus,
      'otherId': otherId,
      'groupId': groupId,
      'source': source,
      'isLook': isLook,
      'type': type,
      'releaseNum': releaseNum,
      'attendNum': attendNum,
      'logo': logo,
      'flagLogo': flagLogo,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'ActiveResult(id: $id, activeType: $activeType, title: $title, subtitle: $subtitle, description: $description, startTime: $startTime, endTime: $endTime)';
  }
}
