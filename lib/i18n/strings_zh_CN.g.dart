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
	@override late final _TranslationsCommonZhCn common = _TranslationsCommonZhCn._(_root);
	@override late final _TranslationsPageZhCn page = _TranslationsPageZhCn._(_root);
	@override late final _TranslationsNoticeZhCn notice = _TranslationsNoticeZhCn._(_root);
	@override late final _TranslationsTitleZhCn title = _TranslationsTitleZhCn._(_root);
	@override late final _TranslationsActionZhCn action = _TranslationsActionZhCn._(_root);
	@override late final _TranslationsLabelZhCn label = _TranslationsLabelZhCn._(_root);
	@override late final _TranslationsFeatZhCn feat = _TranslationsFeatZhCn._(_root);
	@override late final _TranslationsSettingZhCn setting = _TranslationsSettingZhCn._(_root);
	@override late final _TranslationsSubmoduleZhCn submodule = _TranslationsSubmoduleZhCn._(_root);
}

// Path: common
class _TranslationsCommonZhCn implements TranslationsCommonEn {
	_TranslationsCommonZhCn._(this._root);

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
class _TranslationsPageZhCn implements TranslationsPageEn {
	_TranslationsPageZhCn._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get home => '首页';
	@override String get schedule => '日程';
	@override String get notification => '通知';
	@override String get profile => '我';
}

// Path: notice
class _TranslationsNoticeZhCn implements TranslationsNoticeEn {
	_TranslationsNoticeZhCn._(this._root);

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
	@override String get phone_num_empty_hint => '手机号不能为空';
	@override String get ver_code_empty_hint => '验证码不能为空';
	@override String get pwd_empty_hint => '密码不能为空';
	@override String get share_qr_render_error => '二维码生成失败，请使用文件分享';
	@override String get share_failed => '分享失败';
	@override String get failed_open_file => '无法打开文件';
	@override String get checkin_code_hint => '请输入签到码';
}

// Path: title
class _TranslationsTitleZhCn implements TranslationsTitleEn {
	_TranslationsTitleZhCn._(this._root);

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
	@override String get select_checkin_user => '谁要签到？';
	@override String get select_checkin_user_hine => '将为这些用户进行签到';
	@override String get checkin_result => '签到结果';
	@override String week_title({required Object week}) => '第 ${week} 周';
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
}

// Path: action
class _TranslationsActionZhCn implements TranslationsActionEn {
	_TranslationsActionZhCn._(this._root);

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
	@override String get open_with => '打开方式...';
	@override String open_with_name({required Object name}) => '用 ${name} 打开';
	@override String get add_guest => '添加访客账户';
	@override String get re_add_guest => '重新添加访客账户';
	@override String get check_stu_list => '查看选课学生名单';
	@override String get guest_add_by_login => '登录添加';
	@override String get guest_add_by_code => '扫码添加';
	@override String get guest_add_by_file => '从分享文件添加';
	@override String get manual_select_point => '手动选择签到点';
}

// Path: label
class _TranslationsLabelZhCn implements TranslationsLabelEn {
	_TranslationsLabelZhCn._(this._root);

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
	@override String get deadline => '截止';
}

// Path: feat
class _TranslationsFeatZhCn implements TranslationsFeatEn {
	_TranslationsFeatZhCn._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get all_function => '全部功能';
	@override String get schedule => '日程';
	@override String get workspace => '工作台';
}

// Path: setting
class _TranslationsSettingZhCn implements TranslationsSettingEn {
	_TranslationsSettingZhCn._(this._root);

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
}

// Path: submodule
class _TranslationsSubmoduleZhCn implements TranslationsSubmoduleEn {
	_TranslationsSubmoduleZhCn._(this._root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsSubmoduleCquptCheckinZhCn cqupt_checkin = _TranslationsSubmoduleCquptCheckinZhCn._(_root);
	@override late final _TranslationsSubmoduleCquptSportZhCn cqupt_sport = _TranslationsSubmoduleCquptSportZhCn._(_root);
}

// Path: submodule.cqupt_checkin
class _TranslationsSubmoduleCquptCheckinZhCn implements TranslationsSubmoduleCquptCheckinEn {
	_TranslationsSubmoduleCquptCheckinZhCn._(this._root);

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
class _TranslationsSubmoduleCquptSportZhCn implements TranslationsSubmoduleCquptSportEn {
	_TranslationsSubmoduleCquptSportZhCn._(this._root);

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
			'notice.phone_num_empty_hint' => '手机号不能为空',
			'notice.ver_code_empty_hint' => '验证码不能为空',
			'notice.pwd_empty_hint' => '密码不能为空',
			'notice.share_qr_render_error' => '二维码生成失败，请使用文件分享',
			'notice.share_failed' => '分享失败',
			'notice.failed_open_file' => '无法打开文件',
			'notice.checkin_code_hint' => '请输入签到码',
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
			'title.select_checkin_user' => '谁要签到？',
			'title.select_checkin_user_hine' => '将为这些用户进行签到',
			'title.checkin_result' => '签到结果',
			'title.week_title' => ({required Object week}) => '第 ${week} 周',
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
			'action.open_with' => '打开方式...',
			'action.open_with_name' => ({required Object name}) => '用 ${name} 打开',
			'action.add_guest' => '添加访客账户',
			'action.re_add_guest' => '重新添加访客账户',
			'action.check_stu_list' => '查看选课学生名单',
			'action.guest_add_by_login' => '登录添加',
			'action.guest_add_by_code' => '扫码添加',
			'action.guest_add_by_file' => '从分享文件添加',
			'action.manual_select_point' => '手动选择签到点',
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
			_ => null,
		};
	}
}
