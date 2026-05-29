///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZhCn with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhCn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsZhCn _root = this; // ignore: unused_field

	@override 
	TranslationsZhCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhCn(meta: meta ?? this.$meta);

	// Translations
	@override String get app_name => '朋克洛德';
	@override late final _Translations$common$zh_CN common = _Translations$common$zh_CN._(_root);
	@override late final _Translations$page$zh_CN page = _Translations$page$zh_CN._(_root);
	@override late final _Translations$notice$zh_CN notice = _Translations$notice$zh_CN._(_root);
	@override late final _Translations$title$zh_CN title = _Translations$title$zh_CN._(_root);
	@override late final _Translations$action$zh_CN action = _Translations$action$zh_CN._(_root);
	@override late final _Translations$label$zh_CN label = _Translations$label$zh_CN._(_root);
	@override late final _Translations$feat$zh_CN feat = _Translations$feat$zh_CN._(_root);
	@override late final _Translations$setting$zh_CN setting = _Translations$setting$zh_CN._(_root);
	@override late final _Translations$submodule$zh_CN submodule = _Translations$submodule$zh_CN._(_root);
}

// Path: common
class _Translations$common$zh_CN implements Translations$common$en {
	_Translations$common$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get setting => '设置';
	@override String get common => '通用';
	@override String get account => '账户';
	@override String get sources => '源';
	@override String get unify_id => '统一认证码';
	@override String get studnet_id => '学号';
	@override String get name => '姓名';
	@override String get password => '密码';
	@override String get scan_qrcode => '扫码';
	@override String get binary => '二进制';
	@override String get success => '成功';
	@override String get failed => '失败';
}

// Path: page
class _Translations$page$zh_CN implements Translations$page$en {
	_Translations$page$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get home => '首页';
	@override String get schedule => '日程';
	@override String get notification => '通知';
	@override String get profile => '我';
}

// Path: notice
class _Translations$notice$zh_CN implements Translations$notice$en {
	_Translations$notice$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get confirm => '确认';
	@override String get login => '登录';
	@override String get search_school => '通过名称搜索学校...';
	@override String get search_platform => '通过名称搜索平台...';
	@override String get search_user => '通过名称搜索用户...';
	@override String get no_search_result => '没有符合筛选条件的结果';
	@override String get location_service_failed => '启动位置服务失败';
	@override String get location_service_failed_msg => '部分功能受到影响，请检查定位授权';
	@override String get no_avaliable_plat => '该学校没有可用的平台';
	@override String get no_guest => '没有访客账户';
	@override String get login_success => '登录成功';
	@override String get login_failed => '登录失败';
	@override String get refresh_success => '登录状态刷新成功';
	@override String get refresh_failed => '刷新登录状态失败';
	@override String get refresh_failed_hint => '可能需要手动重新登录';
	@override String get not_login => '未登录';
	@override String get logged_in => '已登录';
	@override String get unselected_user => '未选择用户';
	@override String get wait_reource_load => '等待资源加载完成';
	@override String get sport_start_failed => '运动开始时出错';
	@override String get loading => '加载中...';
	@override String get invalid_qr_code => '二维码无效';
	@override String get multi_codes_select => '识别到多个码，请选择一个打开';
	@override String get continue_scan => '继续扫码';
	@override String get open_code_hint => '你希望如何打开这个码？';
	@override String get err_guest_exist => '已经有相同ID的访客账号';
	@override String get current_guest_exist => '当前访客已经存在';
	@override String get not_support_plat => '当前学校不支持该账号所属平台';
	@override String get invalid_data => '数据无效';
	@override String get not_impl_schedule_service => '当前学校未实现日程服务';
	@override String get never_updated => '从未更新';
	@override String get failed_get_data => '获取数据失败';
	@override String get schedule_empty => '今天已经没课了~';
	@override String get schedule_title_hint => '请输入日程标题';
	@override String get schedule_location_hint => '可选，点击右侧按钮在地图上选点';
	@override String get phone_num_empty_hint => '手机号不能为空';
	@override String get ver_code_empty_hint => '验证码不能为空';
	@override String get pwd_empty_hint => '密码不能为空';
	@override String get share_qr_render_error => '二维码生成失败，请使用文件分享';
	@override String get share_failed => '分享失败';
	@override String get failed_open_file => '无法打开文件';
	@override String get checkin_code_hint => '请输入签到码';
	@override String get field_required => '此字段不能为空';
	@override String get invalid_resolution_format => '分辨率格式不正确，应为 720*1280';
}

// Path: title
class _Translations$title$zh_CN implements Translations$title$en {
	_Translations$title$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get id => 'ID';
	@override String get user => '用户';
	@override String get platform => '平台';
	@override String get phone_num => '手机号';
	@override String get verification_code => '验证码';
	@override String get exprire_at => '有效期至';
	@override String get select_school => '选择学校';
	@override String get change_school => '切换学校';
	@override String get login_to => '登录到';
	@override String get already_login => '已经登录到';
	@override String get unknown_platform => '未知平台';
	@override String get select_platform => '选择平台';
	@override String get scan_result => '扫码结果';
	@override String get add_guest => '添加访客账户';
	@override String get add_custom_event => '添加自定义日程';
	@override String get edit_custom_event => '编辑自定义日程';
	@override String get pick_location => '选择地点';
	@override String get select_checkin_user => '谁要签到？';
	@override String get select_checkin_user_hine => '将为这些用户进行签到';
	@override String get checkin_result => '签到结果';
	@override String week_title({required Object week}) => '第 ${week} 周';
	@override String get schedule_title => '日程标题';
	@override String get schedule_description => '描述';
	@override String get schedule_weeks => '周次';
	@override String get schedule_day => '星期';
	@override String get schedule_slot => '时间节次';
	@override String get schedule_color => '颜色';
	@override String get basic_info => '基本信息';
	@override String get time_schedule => '时间安排';
	@override String get slot_span => '跨节数';
	@override String get teacher => '教师';
	@override String get location => '地点';
	@override String get time => '时间';
	@override String get exam_position => '座位号';
	@override String get class_id => '教学班';
	@override String get course_id => '课程号';
	@override String get last_update => '上次更新时间';
	@override String get student_list => '学生名单';
	@override String get select_login_method => '选择登录方式';
	@override String get use_ios_ua => '使用 iOS UA';
	@override String get checkin_code => '签到码';
	@override String get custom_device_info => '自定义登录设备信息';
	@override String get default_device_info_hint => '默认使用本机设备信息登录';
	@override String get custom_device_info_hint => '将使用自定义的设备信息登录';
	@override String get device_platform => '设备平台';
	@override String get device_brand => '设备品牌';
	@override String get device_board => '设备Board';
	@override String get device_model => '设备型号';
	@override String get device_os_ver => '系统版本';
	@override String get device_resolution => '屏幕分辨率';
}

// Path: action
class _Translations$action$zh_CN implements Translations$action$en {
	_Translations$action$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get back => '返回';
	@override String get refresh_login => '刷新登录';
	@override String get refresh_schedule => '刷新日程';
	@override String get logout => '退出登录';
	@override String get re_login => '重新登录';
	@override String get login_info => '登录信息';
	@override String get share_code => '分享码';
	@override String get file_sharing => '使用文件分享';
	@override String get send_sms_code => '发送验证码';
	@override String get pwd_login => '账号密码登录';
	@override String get sms_login => '短信验证码登录';
	@override String get copy => '复制';
	@override String get paste => '粘贴';
	@override String get delete => '删除';
	@override String get edit => '编辑';
	@override String get save => '保存';
	@override String get add => '添加';
	@override String get open_with => '打开方式...';
	@override String open_with_name({required Object name}) => '用 ${name} 打开';
	@override String get add_guest => '添加访客账户';
	@override String get re_add_guest => '重新添加访客账户';
	@override String get check_stu_list => '查看选课学生名单';
	@override String get guest_add_by_login => '登录添加';
	@override String get guest_add_by_code => '扫码添加';
	@override String get guest_add_by_file => '从分享文件添加';
	@override String get manual_select_point => '手动选择签到点';
	@override String get pick_on_map => '在地图上选择';
	@override String get confirm_location => '确认位置';
	@override String get custom_device_info => '自定义设备信息';
	@override String get reset_device_info => '重置设备信息';
}

// Path: label
class _Translations$label$zh_CN implements Translations$label$en {
	_Translations$label$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get primary => '主账号';
	@override String get guest => '访客';
	@override String get expired => '过期';
	@override String get calender_mon => '周一';
	@override String get calender_tue => '周二';
	@override String get calender_wed => '周三';
	@override String get calender_thu => '周四';
	@override String get calender_fri => '周五';
	@override String get calender_sat => '周六';
	@override String get calender_sun => '周日';
	@override String get current_week => '本周';
	@override String get exam => '考试';
	@override String get ongoing => '进行中';
	@override String get upcoming => '即将开始';
	@override String get ended => '已结束';
	@override String get deadline => '截止';
}

// Path: feat
class _Translations$feat$zh_CN implements Translations$feat$en {
	_Translations$feat$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get all_function => '全部功能';
	@override String get schedule => '日程';
	@override String get workspace => '工作台';
}

// Path: setting
class _Translations$setting$zh_CN implements Translations$setting$en {
	_Translations$setting$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get about => '关于';
	@override String get theme => '主题';
	@override String get primary_account => '主账号';
	@override String get guest_account => '访客账号';
	@override String get add_account => '添加账号';
	@override String get password_vault => '密码保管库';
	@override String get dl_cache => '下载缓存';
	@override String get sources_list => '源列表';
	@override String get github_link => 'Github';
	@override String get source_add => '添加源';
	@override String get source_edit => '编辑源';
	@override String get source_delete => '删除源';
	@override String get source_delete_confirm => '确定删除此源？';
	@override String get source_id => '源ID';
	@override String get source_url => 'URL';
	@override String get source_priority => '优先级';
	@override String get source_enabled => '启用';
	@override String get source_id_hint => '请输入源标识';
	@override String get source_url_hint => '请输入源地址';
	@override String get source_priority_hint => '数字越小优先级越高';
	@override String get source_no_sources => '暂无源';
	@override String get source_add_success => '源添加成功';
	@override String get source_update_success => '源更新成功';
	@override String get source_delete_success => '源删除成功';
	@override String get cache_total => '缓存总量';
	@override String get cache_count => '文件数量';
	@override String get cache_no_cache => '暂无缓存';
	@override String get cache_delete_confirm => '确定删除此缓存？';
	@override String get cache_refresh => '刷新缓存';
	@override String get cache_clear_all => '清空所有缓存';
	@override String get cache_clear_all_confirm => '确定清空所有缓存？';
	@override String get cache_last_accessed => '最后访问';
	@override String get cache_never_accessed => '未访问过';
	@override String get cache_detail => '缓存详情';
	@override String get cache_detail_key => '缓存键';
	@override String get cache_detail_path => '文件路径';
	@override String get cache_refreshed => '缓存已刷新';
	@override String get cache_deleted => '缓存已删除';
	@override String cache_cleared({required Object count}) => '已清空 ${count} 个缓存';
}

// Path: submodule
class _Translations$submodule$zh_CN implements Translations$submodule$en {
	_Translations$submodule$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$submodule$cqupt_checkin$zh_CN cqupt_checkin = _Translations$submodule$cqupt_checkin$zh_CN._(_root);
	@override late final _Translations$submodule$cqupt_sport$zh_CN cqupt_sport = _Translations$submodule$cqupt_sport$zh_CN._(_root);
	@override late final _Translations$submodule$chaoxing$zh_CN chaoxing = _Translations$submodule$chaoxing$zh_CN._(_root);
	@override late final _Translations$submodule$sangfor_vpn$zh_CN sangfor_vpn = _Translations$submodule$sangfor_vpn$zh_CN._(_root);
}

// Path: submodule.cqupt_checkin
class _Translations$submodule$cqupt_checkin$zh_CN implements Translations$submodule$cqupt_checkin$en {
	_Translations$submodule$cqupt_checkin$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title_check_in => '重邮统一签到';
	@override String get check_in => '签到';
	@override String get scan_checkin => '扫码签到';
	@override String get qrcode_checkin => '二维码签到';
	@override String get radar_checkin => '雷达签到';
	@override String get pos_checkin => '位置签到';
	@override String get pin_checkin => '签到码签到';
	@override String get gesture_checkin => '手势签到';
	@override String get unsupported_checkin => '不支持的签到方式';
	@override String get checkin_history => '签到记录';
	@override String get checkin_all_success => '签到成功';
	@override String get checkin_all_failed => '签到失败';
	@override String get checkin_partial_failed => '部分签到成功';
	@override String get checkin_fatal_error => '发生致命错误，签到失败';
	@override String get retry_checkin => '重试所选的签到';
	@override String get already_checkin => '已签到';
	@override String get no_ongoing_checkin => '没有进行中的签到';
	@override String get pin_crack_checkin => '暴力破解签到';
	@override String get checkin_use_current_loc => '使用当前位置签到';
	@override String get checkin_use_auto_loc => '自动获取位置签到';
}

// Path: submodule.cqupt_sport
class _Translations$submodule$cqupt_sport$zh_CN implements Translations$submodule$cqupt_sport$en {
	_Translations$submodule$cqupt_sport$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get record => '记录';
	@override String get configure => '配置';
	@override String get motion_profile => '运动预设';
	@override String get start => '开始';
	@override String get stop => '停止';
	@override String get locate => '定位';
	@override String get account => '账号';
	@override String get progress => '进度';
	@override String get remain_time => '剩余';
	@override String get target_distance => '目标';
	@override String get speed => '速度';
	@override String get elapsed_time => '耗时';
	@override String get distance => '里程';
	@override String get pace => '配速';
	@override String get jitter_seed => '抖动种子';
	@override String get jitter_speed => '速度抖动幅度';
	@override String get jitter_pos => '坐标抖动幅度';
	@override String get update_interval => '更新间隔';
	@override String get cfg_distance_hint => '单位为m，建议高出真实目标100m以上';
	@override String get cfg_speed_hint => '单位为m/s，建议为3左右(约5′40″配速)';
	@override String get cfg_speed_jitter_hint => '单位为m/s，值越高抖动越明显，可有效避免查水表';
	@override String get cfg_pos_jitter_hint => '单位为m，值越高抖动越明显，可有效避免查水表';
	@override String get cfg_jitter_seed_hint => '可为空，默认使用时间戳';
	@override String get input_invalid_hint => '请输入正确的值';
	@override String get openid => 'Open ID';
	@override String get openid_hint => '请输入从微信小程序抓包获得的Open ID';
	@override String get choose_mode => '选择跑步模式';
	@override String get mode_auto_run => '自动跑步';
	@override String get mode_normal_run => '正常跑步';
	@override String get mode_traj_record => '轨迹录制';
	@override String get mode_auto_run_tip => '使用运动模拟器自动跑步';
	@override String get mode_normal_run_tip => '我要自己跑';
	@override String get mode_traj_record_tip => '录制运动轨迹，不上传数据';
	@override String get tip_need_stop => '请先停止运动';
	@override String get disabled_by_perm => '已禁用，需要权限';
	@override String get select_user => '谁要跑步？';
	@override String get select_user_hint => '将使用此用户的信息进行运动';
	@override String get valid => '有效';
	@override String get invalid => '无效';
	@override String get sport_type_run => '跑步';
	@override String get sport_type_other => '其他';
	@override String get sport_exam => '考试';
	@override String get sport_addition => '附加';
	@override String get appealable => '可申诉';
	@override String get appeal_success => '申诉成功';
	@override String get appeal_failed => '申诉失败';
	@override String get start_run => '开始运动';
	@override String get stop_run => '停止运动';
	@override String get start_run_tip => '将使用以下配置进行运动';
	@override String get stop_run_tip => '暂未达到目标里程，是否停止运动？';
	@override String get failed_to_get_stats => '获取统计数据失败，请检查是否连接了VPN';
	@override String get portal_user_not_login => '当前用户的门户账号未登录';
	@override String get total_count => '总次数';
	@override String get run_count => '跑步次数';
	@override String get other_count => '其他次数';
	@override String get start_run_notice => '跑步开始';
	@override String get start_run_notice_hint => '请保持应用在前台运行';
	@override String get stop_run_notice => '跑步结束';
	@override String get face_notice => '扫脸通知';
	@override String get face_type_enter => '进场';
	@override String get face_type_leave => '离场';
	@override String get face_type_run => '跑步';
}

// Path: submodule.chaoxing
class _Translations$submodule$chaoxing$zh_CN implements Translations$submodule$chaoxing$en {
	_Translations$submodule$chaoxing$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get courses => '课程';
	@override String get homework => '作业';
	@override String get exam => '考试';
	@override String get messages => '消息';
	@override String get profile => '我';
	@override String get no_courses => '暂无课程';
	@override String get no_activities => '暂无活动';
	@override String get course_activities => '课程活动';
	@override String get teacher => '教师';
	@override String get messages_placeholder => '消息功能即将上线';
}

// Path: submodule.sangfor_vpn
class _Translations$submodule$sangfor_vpn$zh_CN implements Translations$submodule$sangfor_vpn$en {
	_Translations$submodule$sangfor_vpn$zh_CN._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => 'SSL VPN';
	@override String get desc => '通过 Sangfor EasyConnect 连接校园VPN';
	@override String get connect => '连接';
	@override String get disconnect => '断开连接';
	@override String get fill_server_username => '请填写服务器地址和用户名';
	@override String get vpn_setup_failed => 'VPN 初始化失败';
	@override String get vpn_fd_timeout => 'VPN 文件描述符超时';
	@override String get configuration => '配置';
	@override String get server => '服务器';
	@override String get server_hint => 'rvpn.example.com:443';
	@override String get username => '用户名';
	@override String get password => '密码';
	@override String get advanced_settings => '高级设置';
	@override String get totp_secret => 'TOTP 密钥';
	@override String get totp_secret_hint => '可选的2FA种子';
	@override String get custom_dns => '自定义 DNS';
	@override String get custom_dns_hint => '例如 223.5.5.5（可选）';
	@override String get totp_verification => 'TOTP 验证';
	@override String get sms_verification => 'SMS 验证';
	@override String get enter_code => '输入验证码';
	@override String get submit => '提交';
	@override String get status_connected => '已连接';
	@override String get status_tunnel_active => 'VPN 隧道已激活';
	@override String get status_disconnected => '未连接';
	@override String get status_not_connected => '未连接到 VPN';
	@override String get status_connecting => '连接中...';
	@override String get status_establishing => '正在建立连接';
	@override String get status_authenticating => '认证中...';
	@override String get status_login_session => '正在请求登录会话';
	@override String get status_verifying => '验证凭据...';
	@override String get status_submitting => '正在提交登录信息';
	@override String get status_sms_required => '需要 SMS 验证';
	@override String get status_sms_hint => '请输入短信验证码';
	@override String get status_totp_required => '需要 TOTP 验证';
	@override String get status_totp_hint => '请输入 TOTP 验证码';
	@override String get status_getting_token => '获取令牌...';
	@override String get status_exchanging => '正在交换凭据获取令牌';
	@override String get status_fetching => '获取资源...';
	@override String get status_retrieving => '正在获取网络资源';
	@override String get status_assigning_ip => '分配 IP...';
	@override String get status_requesting_ip => '正在请求虚拟 IP 地址';
	@override String get status_opening => '开放通道...';
	@override String get status_channels => '正在建立数据通道';
	@override String get status_failed => '连接失败';
	@override String get status_error_occurred => '发生错误';
	@override String get status_check_logcat => '查看 logcat 获取详情（tag: rust_lib_punklorde）';
}

/// The flat map containing all translations for locale <zh-CN>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhCn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app_name' => '朋克洛德',
			'common.setting' => '设置',
			'common.common' => '通用',
			'common.account' => '账户',
			'common.sources' => '源',
			'common.unify_id' => '统一认证码',
			'common.studnet_id' => '学号',
			'common.name' => '姓名',
			'common.password' => '密码',
			'common.scan_qrcode' => '扫码',
			'common.binary' => '二进制',
			'common.success' => '成功',
			'common.failed' => '失败',
			'page.home' => '首页',
			'page.schedule' => '日程',
			'page.notification' => '通知',
			'page.profile' => '我',
			'notice.cancel' => '取消',
			'notice.confirm' => '确认',
			'notice.login' => '登录',
			'notice.search_school' => '通过名称搜索学校...',
			'notice.search_platform' => '通过名称搜索平台...',
			'notice.search_user' => '通过名称搜索用户...',
			'notice.no_search_result' => '没有符合筛选条件的结果',
			'notice.location_service_failed' => '启动位置服务失败',
			'notice.location_service_failed_msg' => '部分功能受到影响，请检查定位授权',
			'notice.no_avaliable_plat' => '该学校没有可用的平台',
			'notice.no_guest' => '没有访客账户',
			'notice.login_success' => '登录成功',
			'notice.login_failed' => '登录失败',
			'notice.refresh_success' => '登录状态刷新成功',
			'notice.refresh_failed' => '刷新登录状态失败',
			'notice.refresh_failed_hint' => '可能需要手动重新登录',
			'notice.not_login' => '未登录',
			'notice.logged_in' => '已登录',
			'notice.unselected_user' => '未选择用户',
			'notice.wait_reource_load' => '等待资源加载完成',
			'notice.sport_start_failed' => '运动开始时出错',
			'notice.loading' => '加载中...',
			'notice.invalid_qr_code' => '二维码无效',
			'notice.multi_codes_select' => '识别到多个码，请选择一个打开',
			'notice.continue_scan' => '继续扫码',
			'notice.open_code_hint' => '你希望如何打开这个码？',
			'notice.err_guest_exist' => '已经有相同ID的访客账号',
			'notice.current_guest_exist' => '当前访客已经存在',
			'notice.not_support_plat' => '当前学校不支持该账号所属平台',
			'notice.invalid_data' => '数据无效',
			'notice.not_impl_schedule_service' => '当前学校未实现日程服务',
			'notice.never_updated' => '从未更新',
			'notice.failed_get_data' => '获取数据失败',
			'notice.schedule_empty' => '今天已经没课了~',
			'notice.schedule_title_hint' => '请输入日程标题',
			'notice.schedule_location_hint' => '可选，点击右侧按钮在地图上选点',
			'notice.phone_num_empty_hint' => '手机号不能为空',
			'notice.ver_code_empty_hint' => '验证码不能为空',
			'notice.pwd_empty_hint' => '密码不能为空',
			'notice.share_qr_render_error' => '二维码生成失败，请使用文件分享',
			'notice.share_failed' => '分享失败',
			'notice.failed_open_file' => '无法打开文件',
			'notice.checkin_code_hint' => '请输入签到码',
			'notice.field_required' => '此字段不能为空',
			'notice.invalid_resolution_format' => '分辨率格式不正确，应为 720*1280',
			'title.id' => 'ID',
			'title.user' => '用户',
			'title.platform' => '平台',
			'title.phone_num' => '手机号',
			'title.verification_code' => '验证码',
			'title.exprire_at' => '有效期至',
			'title.select_school' => '选择学校',
			'title.change_school' => '切换学校',
			'title.login_to' => '登录到',
			'title.already_login' => '已经登录到',
			'title.unknown_platform' => '未知平台',
			'title.select_platform' => '选择平台',
			'title.scan_result' => '扫码结果',
			'title.add_guest' => '添加访客账户',
			'title.add_custom_event' => '添加自定义日程',
			'title.edit_custom_event' => '编辑自定义日程',
			'title.pick_location' => '选择地点',
			'title.select_checkin_user' => '谁要签到？',
			'title.select_checkin_user_hine' => '将为这些用户进行签到',
			'title.checkin_result' => '签到结果',
			'title.week_title' => ({required Object week}) => '第 ${week} 周',
			'title.schedule_title' => '日程标题',
			'title.schedule_description' => '描述',
			'title.schedule_weeks' => '周次',
			'title.schedule_day' => '星期',
			'title.schedule_slot' => '时间节次',
			'title.schedule_color' => '颜色',
			'title.basic_info' => '基本信息',
			'title.time_schedule' => '时间安排',
			'title.slot_span' => '跨节数',
			'title.teacher' => '教师',
			'title.location' => '地点',
			'title.time' => '时间',
			'title.exam_position' => '座位号',
			'title.class_id' => '教学班',
			'title.course_id' => '课程号',
			'title.last_update' => '上次更新时间',
			'title.student_list' => '学生名单',
			'title.select_login_method' => '选择登录方式',
			'title.use_ios_ua' => '使用 iOS UA',
			'title.checkin_code' => '签到码',
			'title.custom_device_info' => '自定义登录设备信息',
			'title.default_device_info_hint' => '默认使用本机设备信息登录',
			'title.custom_device_info_hint' => '将使用自定义的设备信息登录',
			'title.device_platform' => '设备平台',
			'title.device_brand' => '设备品牌',
			'title.device_board' => '设备Board',
			'title.device_model' => '设备型号',
			'title.device_os_ver' => '系统版本',
			'title.device_resolution' => '屏幕分辨率',
			'action.back' => '返回',
			'action.refresh_login' => '刷新登录',
			'action.refresh_schedule' => '刷新日程',
			'action.logout' => '退出登录',
			'action.re_login' => '重新登录',
			'action.login_info' => '登录信息',
			'action.share_code' => '分享码',
			'action.file_sharing' => '使用文件分享',
			'action.send_sms_code' => '发送验证码',
			'action.pwd_login' => '账号密码登录',
			'action.sms_login' => '短信验证码登录',
			'action.copy' => '复制',
			'action.paste' => '粘贴',
			'action.delete' => '删除',
			'action.edit' => '编辑',
			'action.save' => '保存',
			'action.add' => '添加',
			'action.open_with' => '打开方式...',
			'action.open_with_name' => ({required Object name}) => '用 ${name} 打开',
			'action.add_guest' => '添加访客账户',
			'action.re_add_guest' => '重新添加访客账户',
			'action.check_stu_list' => '查看选课学生名单',
			'action.guest_add_by_login' => '登录添加',
			'action.guest_add_by_code' => '扫码添加',
			'action.guest_add_by_file' => '从分享文件添加',
			'action.manual_select_point' => '手动选择签到点',
			'action.pick_on_map' => '在地图上选择',
			'action.confirm_location' => '确认位置',
			'action.custom_device_info' => '自定义设备信息',
			'action.reset_device_info' => '重置设备信息',
			'label.primary' => '主账号',
			'label.guest' => '访客',
			'label.expired' => '过期',
			'label.calender_mon' => '周一',
			'label.calender_tue' => '周二',
			'label.calender_wed' => '周三',
			'label.calender_thu' => '周四',
			'label.calender_fri' => '周五',
			'label.calender_sat' => '周六',
			'label.calender_sun' => '周日',
			'label.current_week' => '本周',
			'label.exam' => '考试',
			'label.ongoing' => '进行中',
			'label.upcoming' => '即将开始',
			'label.ended' => '已结束',
			'label.deadline' => '截止',
			'feat.all_function' => '全部功能',
			'feat.schedule' => '日程',
			'feat.workspace' => '工作台',
			'setting.about' => '关于',
			'setting.theme' => '主题',
			'setting.primary_account' => '主账号',
			'setting.guest_account' => '访客账号',
			'setting.add_account' => '添加账号',
			'setting.password_vault' => '密码保管库',
			'setting.dl_cache' => '下载缓存',
			'setting.sources_list' => '源列表',
			'setting.github_link' => 'Github',
			'setting.source_add' => '添加源',
			'setting.source_edit' => '编辑源',
			'setting.source_delete' => '删除源',
			'setting.source_delete_confirm' => '确定删除此源？',
			'setting.source_id' => '源ID',
			'setting.source_url' => 'URL',
			'setting.source_priority' => '优先级',
			'setting.source_enabled' => '启用',
			'setting.source_id_hint' => '请输入源标识',
			'setting.source_url_hint' => '请输入源地址',
			'setting.source_priority_hint' => '数字越小优先级越高',
			'setting.source_no_sources' => '暂无源',
			'setting.source_add_success' => '源添加成功',
			'setting.source_update_success' => '源更新成功',
			'setting.source_delete_success' => '源删除成功',
			'setting.cache_total' => '缓存总量',
			'setting.cache_count' => '文件数量',
			'setting.cache_no_cache' => '暂无缓存',
			'setting.cache_delete_confirm' => '确定删除此缓存？',
			'setting.cache_refresh' => '刷新缓存',
			'setting.cache_clear_all' => '清空所有缓存',
			'setting.cache_clear_all_confirm' => '确定清空所有缓存？',
			'setting.cache_last_accessed' => '最后访问',
			'setting.cache_never_accessed' => '未访问过',
			'setting.cache_detail' => '缓存详情',
			'setting.cache_detail_key' => '缓存键',
			'setting.cache_detail_path' => '文件路径',
			'setting.cache_refreshed' => '缓存已刷新',
			'setting.cache_deleted' => '缓存已删除',
			'setting.cache_cleared' => ({required Object count}) => '已清空 ${count} 个缓存',
			'submodule.cqupt_checkin.title_check_in' => '重邮统一签到',
			'submodule.cqupt_checkin.check_in' => '签到',
			'submodule.cqupt_checkin.scan_checkin' => '扫码签到',
			'submodule.cqupt_checkin.qrcode_checkin' => '二维码签到',
			'submodule.cqupt_checkin.radar_checkin' => '雷达签到',
			'submodule.cqupt_checkin.pos_checkin' => '位置签到',
			'submodule.cqupt_checkin.pin_checkin' => '签到码签到',
			'submodule.cqupt_checkin.gesture_checkin' => '手势签到',
			'submodule.cqupt_checkin.unsupported_checkin' => '不支持的签到方式',
			'submodule.cqupt_checkin.checkin_history' => '签到记录',
			'submodule.cqupt_checkin.checkin_all_success' => '签到成功',
			'submodule.cqupt_checkin.checkin_all_failed' => '签到失败',
			'submodule.cqupt_checkin.checkin_partial_failed' => '部分签到成功',
			'submodule.cqupt_checkin.checkin_fatal_error' => '发生致命错误，签到失败',
			'submodule.cqupt_checkin.retry_checkin' => '重试所选的签到',
			'submodule.cqupt_checkin.already_checkin' => '已签到',
			'submodule.cqupt_checkin.no_ongoing_checkin' => '没有进行中的签到',
			'submodule.cqupt_checkin.pin_crack_checkin' => '暴力破解签到',
			'submodule.cqupt_checkin.checkin_use_current_loc' => '使用当前位置签到',
			'submodule.cqupt_checkin.checkin_use_auto_loc' => '自动获取位置签到',
			'submodule.cqupt_sport.record' => '记录',
			'submodule.cqupt_sport.configure' => '配置',
			'submodule.cqupt_sport.motion_profile' => '运动预设',
			'submodule.cqupt_sport.start' => '开始',
			'submodule.cqupt_sport.stop' => '停止',
			'submodule.cqupt_sport.locate' => '定位',
			'submodule.cqupt_sport.account' => '账号',
			'submodule.cqupt_sport.progress' => '进度',
			'submodule.cqupt_sport.remain_time' => '剩余',
			'submodule.cqupt_sport.target_distance' => '目标',
			'submodule.cqupt_sport.speed' => '速度',
			'submodule.cqupt_sport.elapsed_time' => '耗时',
			'submodule.cqupt_sport.distance' => '里程',
			'submodule.cqupt_sport.pace' => '配速',
			'submodule.cqupt_sport.jitter_seed' => '抖动种子',
			'submodule.cqupt_sport.jitter_speed' => '速度抖动幅度',
			'submodule.cqupt_sport.jitter_pos' => '坐标抖动幅度',
			'submodule.cqupt_sport.update_interval' => '更新间隔',
			'submodule.cqupt_sport.cfg_distance_hint' => '单位为m，建议高出真实目标100m以上',
			'submodule.cqupt_sport.cfg_speed_hint' => '单位为m/s，建议为3左右(约5′40″配速)',
			'submodule.cqupt_sport.cfg_speed_jitter_hint' => '单位为m/s，值越高抖动越明显，可有效避免查水表',
			'submodule.cqupt_sport.cfg_pos_jitter_hint' => '单位为m，值越高抖动越明显，可有效避免查水表',
			'submodule.cqupt_sport.cfg_jitter_seed_hint' => '可为空，默认使用时间戳',
			'submodule.cqupt_sport.input_invalid_hint' => '请输入正确的值',
			'submodule.cqupt_sport.openid' => 'Open ID',
			'submodule.cqupt_sport.openid_hint' => '请输入从微信小程序抓包获得的Open ID',
			'submodule.cqupt_sport.choose_mode' => '选择跑步模式',
			'submodule.cqupt_sport.mode_auto_run' => '自动跑步',
			'submodule.cqupt_sport.mode_normal_run' => '正常跑步',
			'submodule.cqupt_sport.mode_traj_record' => '轨迹录制',
			'submodule.cqupt_sport.mode_auto_run_tip' => '使用运动模拟器自动跑步',
			'submodule.cqupt_sport.mode_normal_run_tip' => '我要自己跑',
			'submodule.cqupt_sport.mode_traj_record_tip' => '录制运动轨迹，不上传数据',
			'submodule.cqupt_sport.tip_need_stop' => '请先停止运动',
			'submodule.cqupt_sport.disabled_by_perm' => '已禁用，需要权限',
			'submodule.cqupt_sport.select_user' => '谁要跑步？',
			'submodule.cqupt_sport.select_user_hint' => '将使用此用户的信息进行运动',
			'submodule.cqupt_sport.valid' => '有效',
			'submodule.cqupt_sport.invalid' => '无效',
			'submodule.cqupt_sport.sport_type_run' => '跑步',
			'submodule.cqupt_sport.sport_type_other' => '其他',
			'submodule.cqupt_sport.sport_exam' => '考试',
			'submodule.cqupt_sport.sport_addition' => '附加',
			'submodule.cqupt_sport.appealable' => '可申诉',
			'submodule.cqupt_sport.appeal_success' => '申诉成功',
			'submodule.cqupt_sport.appeal_failed' => '申诉失败',
			'submodule.cqupt_sport.start_run' => '开始运动',
			'submodule.cqupt_sport.stop_run' => '停止运动',
			'submodule.cqupt_sport.start_run_tip' => '将使用以下配置进行运动',
			'submodule.cqupt_sport.stop_run_tip' => '暂未达到目标里程，是否停止运动？',
			'submodule.cqupt_sport.failed_to_get_stats' => '获取统计数据失败，请检查是否连接了VPN',
			'submodule.cqupt_sport.portal_user_not_login' => '当前用户的门户账号未登录',
			'submodule.cqupt_sport.total_count' => '总次数',
			'submodule.cqupt_sport.run_count' => '跑步次数',
			'submodule.cqupt_sport.other_count' => '其他次数',
			'submodule.cqupt_sport.start_run_notice' => '跑步开始',
			'submodule.cqupt_sport.start_run_notice_hint' => '请保持应用在前台运行',
			'submodule.cqupt_sport.stop_run_notice' => '跑步结束',
			'submodule.cqupt_sport.face_notice' => '扫脸通知',
			'submodule.cqupt_sport.face_type_enter' => '进场',
			'submodule.cqupt_sport.face_type_leave' => '离场',
			'submodule.cqupt_sport.face_type_run' => '跑步',
			'submodule.chaoxing.courses' => '课程',
			'submodule.chaoxing.homework' => '作业',
			'submodule.chaoxing.exam' => '考试',
			'submodule.chaoxing.messages' => '消息',
			'submodule.chaoxing.profile' => '我',
			'submodule.chaoxing.no_courses' => '暂无课程',
			'submodule.chaoxing.no_activities' => '暂无活动',
			'submodule.chaoxing.course_activities' => '课程活动',
			'submodule.chaoxing.teacher' => '教师',
			'submodule.chaoxing.messages_placeholder' => '消息功能即将上线',
			'submodule.sangfor_vpn.title' => 'SSL VPN',
			'submodule.sangfor_vpn.desc' => '通过 Sangfor EasyConnect 连接校园VPN',
			'submodule.sangfor_vpn.connect' => '连接',
			'submodule.sangfor_vpn.disconnect' => '断开连接',
			'submodule.sangfor_vpn.fill_server_username' => '请填写服务器地址和用户名',
			'submodule.sangfor_vpn.vpn_setup_failed' => 'VPN 初始化失败',
			'submodule.sangfor_vpn.vpn_fd_timeout' => 'VPN 文件描述符超时',
			'submodule.sangfor_vpn.configuration' => '配置',
			'submodule.sangfor_vpn.server' => '服务器',
			'submodule.sangfor_vpn.server_hint' => 'rvpn.example.com:443',
			'submodule.sangfor_vpn.username' => '用户名',
			'submodule.sangfor_vpn.password' => '密码',
			'submodule.sangfor_vpn.advanced_settings' => '高级设置',
			'submodule.sangfor_vpn.totp_secret' => 'TOTP 密钥',
			'submodule.sangfor_vpn.totp_secret_hint' => '可选的2FA种子',
			'submodule.sangfor_vpn.custom_dns' => '自定义 DNS',
			'submodule.sangfor_vpn.custom_dns_hint' => '例如 223.5.5.5（可选）',
			'submodule.sangfor_vpn.totp_verification' => 'TOTP 验证',
			'submodule.sangfor_vpn.sms_verification' => 'SMS 验证',
			'submodule.sangfor_vpn.enter_code' => '输入验证码',
			'submodule.sangfor_vpn.submit' => '提交',
			'submodule.sangfor_vpn.status_connected' => '已连接',
			'submodule.sangfor_vpn.status_tunnel_active' => 'VPN 隧道已激活',
			'submodule.sangfor_vpn.status_disconnected' => '未连接',
			'submodule.sangfor_vpn.status_not_connected' => '未连接到 VPN',
			'submodule.sangfor_vpn.status_connecting' => '连接中...',
			'submodule.sangfor_vpn.status_establishing' => '正在建立连接',
			'submodule.sangfor_vpn.status_authenticating' => '认证中...',
			'submodule.sangfor_vpn.status_login_session' => '正在请求登录会话',
			'submodule.sangfor_vpn.status_verifying' => '验证凭据...',
			'submodule.sangfor_vpn.status_submitting' => '正在提交登录信息',
			'submodule.sangfor_vpn.status_sms_required' => '需要 SMS 验证',
			'submodule.sangfor_vpn.status_sms_hint' => '请输入短信验证码',
			'submodule.sangfor_vpn.status_totp_required' => '需要 TOTP 验证',
			'submodule.sangfor_vpn.status_totp_hint' => '请输入 TOTP 验证码',
			'submodule.sangfor_vpn.status_getting_token' => '获取令牌...',
			'submodule.sangfor_vpn.status_exchanging' => '正在交换凭据获取令牌',
			'submodule.sangfor_vpn.status_fetching' => '获取资源...',
			'submodule.sangfor_vpn.status_retrieving' => '正在获取网络资源',
			'submodule.sangfor_vpn.status_assigning_ip' => '分配 IP...',
			'submodule.sangfor_vpn.status_requesting_ip' => '正在请求虚拟 IP 地址',
			'submodule.sangfor_vpn.status_opening' => '开放通道...',
			'submodule.sangfor_vpn.status_channels' => '正在建立数据通道',
			'submodule.sangfor_vpn.status_failed' => '连接失败',
			'submodule.sangfor_vpn.status_error_occurred' => '发生错误',
			'submodule.sangfor_vpn.status_check_logcat' => '查看 logcat 获取详情（tag: rust_lib_punklorde）',
			_ => null,
		};
	}
}
