///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Punklorde'
	String get app_name => 'Punklorde';

	late final TranslationsCommonEn common = TranslationsCommonEn._(_root);
	late final TranslationsPageEn page = TranslationsPageEn._(_root);
	late final TranslationsNoticeEn notice = TranslationsNoticeEn._(_root);
	late final TranslationsTitleEn title = TranslationsTitleEn._(_root);
	late final TranslationsActionEn action = TranslationsActionEn._(_root);
	late final TranslationsLabelEn label = TranslationsLabelEn._(_root);
	late final TranslationsFeatEn feat = TranslationsFeatEn._(_root);
	late final TranslationsSettingEn setting = TranslationsSettingEn._(_root);
	late final TranslationsSubmoduleEn submodule = TranslationsSubmoduleEn._(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Setting'
	String get setting => 'Setting';

	/// en: 'Common'
	String get common => 'Common';

	/// en: 'Account'
	String get account => 'Account';

	/// en: 'Sources'
	String get sources => 'Sources';

	/// en: 'Unify ID'
	String get unify_id => 'Unify ID';

	/// en: 'Student ID'
	String get studnet_id => 'Student ID';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Scan'
	String get scan_qrcode => 'Scan';

	/// en: 'Binary'
	String get binary => 'Binary';

	/// en: 'Success'
	String get success => 'Success';

	/// en: 'Failed'
	String get failed => 'Failed';
}

// Path: page
class TranslationsPageEn {
	TranslationsPageEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Schedule'
	String get schedule => 'Schedule';

	/// en: 'Notice'
	String get notification => 'Notice';

	/// en: 'Profile'
	String get profile => 'Profile';
}

// Path: notice
class TranslationsNoticeEn {
	TranslationsNoticeEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Login'
	String get login => 'Login';

	/// en: 'Search for schools by name...'
	String get search_school => 'Search for schools by name...';

	/// en: 'Search for platforms by name...'
	String get search_platform => 'Search for platforms by name...';

	/// en: 'Search for users by name...'
	String get search_user => 'Search for users by name...';

	/// en: 'No results meet the filtering criteria'
	String get no_search_result => 'No results meet the filtering criteria';

	/// en: 'Failed to start location service'
	String get location_service_failed => 'Failed to start location service';

	/// en: 'This will affect some functions, please check if the location permission is authorized.'
	String get location_service_failed_msg => 'This will affect some functions, please check if the location permission is authorized.';

	/// en: 'There is no available platform at this school.'
	String get no_avaliable_plat => 'There is no available platform at this school.';

	/// en: 'There is no guest account.'
	String get no_guest => 'There is no guest account.';

	/// en: 'Login successfully'
	String get login_success => 'Login successfully';

	/// en: 'Login failed'
	String get login_failed => 'Login failed';

	/// en: 'Login status refreshed successfully'
	String get refresh_success => 'Login status refreshed successfully';

	/// en: 'Failed to refresh login status'
	String get refresh_failed => 'Failed to refresh login status';

	/// en: 'Manual re-login may be required.'
	String get refresh_failed_hint => 'Manual re-login may be required.';

	/// en: 'Not logged in'
	String get not_login => 'Not logged in';

	/// en: 'Logged in'
	String get logged_in => 'Logged in';

	/// en: 'Unselected user.'
	String get unselected_user => 'Unselected user.';

	/// en: 'Wait for the resources to load completely.'
	String get wait_reource_load => 'Wait for the resources to load completely.';

	/// en: 'Error occurred during the start of the sport.'
	String get sport_start_failed => 'Error occurred during the start of the sport.';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Invalid code'
	String get invalid_qr_code => 'Invalid code';

	/// en: 'Multiple codes have been identified. Please select one to open.'
	String get multi_codes_select => 'Multiple codes have been identified. Please select one to open.';

	/// en: 'Continue scanning'
	String get continue_scan => 'Continue scanning';

	/// en: 'How would you like to open this code?'
	String get open_code_hint => 'How would you like to open this code?';

	/// en: 'Guest accounts with the same ID already exist.'
	String get err_guest_exist => 'Guest accounts with the same ID already exist.';

	/// en: 'This guest already exists.'
	String get current_guest_exist => 'This guest already exists.';

	/// en: 'The current school does not support the platform associated with this account.'
	String get not_support_plat => 'The current school does not support the platform associated with this account.';

	/// en: 'Invalid data'
	String get invalid_data => 'Invalid data';

	/// en: 'This school has not implemented the schedule service.'
	String get not_impl_schedule_service => 'This school has not implemented the schedule service.';

	/// en: 'Never updated'
	String get never_updated => 'Never updated';

	/// en: 'Failed to obtain data'
	String get failed_get_data => 'Failed to obtain data';

	/// en: 'There are no classes today ~'
	String get schedule_empty => 'There are no classes today ~';

	/// en: 'Phone number cannot be blank'
	String get phone_num_empty_hint => 'Phone number cannot be blank';

	/// en: 'Verification code cannot be blank'
	String get ver_code_empty_hint => 'Verification code cannot be blank';

	/// en: 'Password cannot be blank'
	String get pwd_empty_hint => 'Password cannot be blank';

	/// en: 'QR code generation failed. Please use file sharing instead.'
	String get share_qr_render_error => 'QR code generation failed. Please use file sharing instead.';

	/// en: 'Share failed'
	String get share_failed => 'Share failed';

	/// en: 'Failed to open file'
	String get failed_open_file => 'Failed to open file';

	/// en: 'Please enter the check-in code'
	String get checkin_code_hint => 'Please enter the check-in code';
}

// Path: title
class TranslationsTitleEn {
	TranslationsTitleEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'ID'
	String get id => 'ID';

	/// en: 'User'
	String get user => 'User';

	/// en: 'Platform'
	String get platform => 'Platform';

	/// en: 'Phone number'
	String get phone_num => 'Phone number';

	/// en: 'Verification code'
	String get verification_code => 'Verification code';

	/// en: 'Expires at'
	String get exprire_at => 'Expires at';

	/// en: 'Select School'
	String get select_school => 'Select School';

	/// en: 'Change School'
	String get change_school => 'Change School';

	/// en: 'Login to'
	String get login_to => 'Login to';

	/// en: 'Already logged into'
	String get already_login => 'Already logged into';

	/// en: 'Unknown Platform'
	String get unknown_platform => 'Unknown Platform';

	/// en: 'Select Platform'
	String get select_platform => 'Select Platform';

	/// en: 'Scanning results'
	String get scan_result => 'Scanning results';

	/// en: 'Add Guest Account'
	String get add_guest => 'Add Guest Account';

	/// en: 'Select the Users'
	String get select_checkin_user => 'Select the Users';

	/// en: 'These users will be used for checking in.'
	String get select_checkin_user_hine => 'These users will be used for checking in.';

	/// en: 'Check-in Result'
	String get checkin_result => 'Check-in Result';

	/// en: 'Week $week'
	String week_title({required Object week}) => 'Week ${week}';

	/// en: 'Teacher'
	String get teacher => 'Teacher';

	/// en: 'Location'
	String get location => 'Location';

	/// en: 'Time'
	String get time => 'Time';

	/// en: 'Seat'
	String get exam_position => 'Seat';

	/// en: 'Class'
	String get class_id => 'Class';

	/// en: 'Course'
	String get course_id => 'Course';

	/// en: 'Last update'
	String get last_update => 'Last update';

	/// en: 'Students List'
	String get student_list => 'Students List';

	/// en: 'Select the login method'
	String get select_login_method => 'Select the login method';

	/// en: 'Use iOS UA'
	String get use_ios_ua => 'Use iOS UA';

	/// en: 'Check-in Code'
	String get checkin_code => 'Check-in Code';
}

// Path: action
class TranslationsActionEn {
	TranslationsActionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Refresh the login status'
	String get refresh_login => 'Refresh the login status';

	/// en: 'Refresh schedule'
	String get refresh_schedule => 'Refresh schedule';

	/// en: 'Logout'
	String get logout => 'Logout';

	/// en: 'Re-login'
	String get re_login => 'Re-login';

	/// en: 'Login Information'
	String get login_info => 'Login Information';

	/// en: 'Share Code'
	String get share_code => 'Share Code';

	/// en: 'Using file sharing'
	String get file_sharing => 'Using file sharing';

	/// en: 'Send SMS Code'
	String get send_sms_code => 'Send SMS Code';

	/// en: 'Password Login'
	String get pwd_login => 'Password Login';

	/// en: 'SMS Login'
	String get sms_login => 'SMS Login';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Open with...'
	String get open_with => 'Open with...';

	/// en: 'Open with $name'
	String open_with_name({required Object name}) => 'Open with ${name}';

	/// en: 'Add guest account'
	String get add_guest => 'Add guest account';

	/// en: 'Re-add guest account'
	String get re_add_guest => 'Re-add guest account';

	/// en: 'Check students list'
	String get check_stu_list => 'Check students list';

	/// en: 'Add by login'
	String get guest_add_by_login => 'Add by login';

	/// en: 'Add from share code'
	String get guest_add_by_code => 'Add from share code';

	/// en: 'Add from share file'
	String get guest_add_by_file => 'Add from share file';

	/// en: 'Manually select check-in point'
	String get manual_select_point => 'Manually select check-in point';
}

// Path: label
class TranslationsLabelEn {
	TranslationsLabelEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Primary'
	String get primary => 'Primary';

	/// en: 'Guest'
	String get guest => 'Guest';

	/// en: 'Expired'
	String get expired => 'Expired';

	/// en: 'Mon.'
	String get calender_mon => 'Mon.';

	/// en: 'Tue.'
	String get calender_tue => 'Tue.';

	/// en: 'Wed.'
	String get calender_wed => 'Wed.';

	/// en: 'Thu.'
	String get calender_thu => 'Thu.';

	/// en: 'Fri.'
	String get calender_fri => 'Fri.';

	/// en: 'Sat.'
	String get calender_sat => 'Sat.';

	/// en: 'Sun.'
	String get calender_sun => 'Sun.';

	/// en: 'Current'
	String get current_week => 'Current';

	/// en: 'Exam'
	String get exam => 'Exam';

	/// en: 'Ongoing'
	String get ongoing => 'Ongoing';

	/// en: 'Upcoming'
	String get upcoming => 'Upcoming';

	/// en: 'Deadline'
	String get deadline => 'Deadline';
}

// Path: feat
class TranslationsFeatEn {
	TranslationsFeatEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'All Features'
	String get all_function => 'All Features';

	/// en: 'Schedule'
	String get schedule => 'Schedule';

	/// en: 'Workspace'
	String get workspace => 'Workspace';
}

// Path: setting
class TranslationsSettingEn {
	TranslationsSettingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About'
	String get about => 'About';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Primary Account'
	String get primary_account => 'Primary Account';

	/// en: 'Guest Account'
	String get guest_account => 'Guest Account';

	/// en: 'Add Account'
	String get add_account => 'Add Account';

	/// en: 'Password Vault'
	String get password_vault => 'Password Vault';

	/// en: 'Download Cache'
	String get dl_cache => 'Download Cache';

	/// en: 'Sources List'
	String get sources_list => 'Sources List';

	/// en: 'Github'
	String get github_link => 'Github';
}

// Path: submodule
class TranslationsSubmoduleEn {
	TranslationsSubmoduleEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsSubmoduleCquptCheckinEn cqupt_checkin = TranslationsSubmoduleCquptCheckinEn._(_root);
	late final TranslationsSubmoduleCquptSportEn cqupt_sport = TranslationsSubmoduleCquptSportEn._(_root);
}

// Path: submodule.cqupt_checkin
class TranslationsSubmoduleCquptCheckinEn {
	TranslationsSubmoduleCquptCheckinEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Check-in'
	String get title_check_in => 'Check-in';

	/// en: 'Check in'
	String get check_in => 'Check in';

	/// en: 'Scan'
	String get scan_checkin => 'Scan';

	/// en: 'QR Code Check-in'
	String get qrcode_checkin => 'QR Code Check-in';

	/// en: 'Radar Check-in'
	String get radar_checkin => 'Radar Check-in';

	/// en: 'Position Check-in'
	String get pos_checkin => 'Position Check-in';

	/// en: 'Pin Check-in'
	String get pin_checkin => 'Pin Check-in';

	/// en: 'Gesture Check-in'
	String get gesture_checkin => 'Gesture Check-in';

	/// en: 'Unsupported Check-in'
	String get unsupported_checkin => 'Unsupported Check-in';

	/// en: 'Check-in History'
	String get checkin_history => 'Check-in History';

	/// en: 'Check-in Successful'
	String get checkin_all_success => 'Check-in Successful';

	/// en: 'Check-in Failed'
	String get checkin_all_failed => 'Check-in Failed';

	/// en: 'Partial Check-in Successful'
	String get checkin_partial_failed => 'Partial Check-in Successful';

	/// en: 'A fatal error occurred, and the check-in failed.'
	String get checkin_fatal_error => 'A fatal error occurred, and the check-in failed.';

	/// en: 'Retry selected check-in'
	String get retry_checkin => 'Retry selected check-in';

	/// en: 'Already checked in'
	String get already_checkin => 'Already checked in';

	/// en: 'No ongoing check-in process'
	String get no_ongoing_checkin => 'No ongoing check-in process';

	/// en: 'Brute force check-in'
	String get pin_crack_checkin => 'Brute force check-in';

	/// en: 'Current Location'
	String get checkin_use_current_loc => 'Current Location';

	/// en: 'Auto-Obtain Location'
	String get checkin_use_auto_loc => 'Auto-Obtain Location';
}

// Path: submodule.cqupt_sport
class TranslationsSubmoduleCquptSportEn {
	TranslationsSubmoduleCquptSportEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Record'
	String get record => 'Record';

	/// en: 'Configure'
	String get configure => 'Configure';

	/// en: 'Motion Profile'
	String get motion_profile => 'Motion Profile';

	/// en: 'Start'
	String get start => 'Start';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Locate'
	String get locate => 'Locate';

	/// en: 'Account'
	String get account => 'Account';

	/// en: 'Progress'
	String get progress => 'Progress';

	/// en: 'Remain'
	String get remain_time => 'Remain';

	/// en: 'Target'
	String get target_distance => 'Target';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Elapsed Time'
	String get elapsed_time => 'Elapsed Time';

	/// en: 'Distance'
	String get distance => 'Distance';

	/// en: 'Pace'
	String get pace => 'Pace';

	/// en: 'Jitter Seed'
	String get jitter_seed => 'Jitter Seed';

	/// en: 'Speed Jitter Amplitude'
	String get jitter_speed => 'Speed Jitter Amplitude';

	/// en: 'Position Jitter Amplitude'
	String get jitter_pos => 'Position Jitter Amplitude';

	/// en: 'Update Interval'
	String get update_interval => 'Update Interval';

	/// en: 'In meters. It is recommended to be 100 meters or more above the actual target'
	String get cfg_distance_hint => 'In meters. It is recommended to be 100 meters or more above the actual target';

	/// en: 'In m/s. It is recommended to be around 3 (approximately 5′40″ pace)'
	String get cfg_speed_hint => 'In m/s. It is recommended to be around 3 (approximately 5′40″ pace)';

	/// en: 'In m/s. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking'
	String get cfg_speed_jitter_hint => 'In m/s. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking';

	/// en: 'In meters. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking'
	String get cfg_pos_jitter_hint => 'In meters. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking';

	/// en: 'Can be empty. The default is to use the timestamp'
	String get cfg_jitter_seed_hint => 'Can be empty. The default is to use the timestamp';

	/// en: 'Please enter the correct value.'
	String get input_invalid_hint => 'Please enter the correct value.';

	/// en: 'Open ID'
	String get openid => 'Open ID';

	/// en: 'Please enter the Open ID obtained by capturing data from the WeChat mini-program.'
	String get openid_hint => 'Please enter the Open ID obtained by capturing data from the WeChat mini-program.';

	/// en: 'Choose Running Mode'
	String get choose_mode => 'Choose Running Mode';

	/// en: 'Automatic Running'
	String get mode_auto_run => 'Automatic Running';

	/// en: 'Normal Running'
	String get mode_normal_run => 'Normal Running';

	/// en: 'Trajectory Recording'
	String get mode_traj_record => 'Trajectory Recording';

	/// en: 'Using a motion simulator for automatic running.'
	String get mode_auto_run_tip => 'Using a motion simulator for automatic running.';

	/// en: 'I'll run by myself.'
	String get mode_normal_run_tip => 'I\'ll run by myself.';

	/// en: 'Records the movement trajectory but does not upload the data.'
	String get mode_traj_record_tip => 'Records the movement trajectory but does not upload the data.';

	/// en: 'Please stop the running before exiting.'
	String get tip_need_stop => 'Please stop the running before exiting.';

	/// en: 'DISABLED. Requires permission.'
	String get disabled_by_perm => 'DISABLED. Requires permission.';

	/// en: 'Select a User'
	String get select_user => 'Select a User';

	/// en: 'This user's information will be used for running.'
	String get select_user_hint => 'This user\'s information will be used for running.';

	/// en: 'Valid'
	String get valid => 'Valid';

	/// en: 'Invalid'
	String get invalid => 'Invalid';

	/// en: 'Running'
	String get sport_type_run => 'Running';

	/// en: 'Other'
	String get sport_type_other => 'Other';

	/// en: 'Exam'
	String get sport_exam => 'Exam';

	/// en: 'Addition'
	String get sport_addition => 'Addition';

	/// en: 'Appealable'
	String get appealable => 'Appealable';

	/// en: 'Appeal Successful'
	String get appeal_success => 'Appeal Successful';

	/// en: 'Appeal Failed'
	String get appeal_failed => 'Appeal Failed';

	/// en: 'Start Running'
	String get start_run => 'Start Running';

	/// en: 'Stop Running'
	String get stop_run => 'Stop Running';

	/// en: 'The following configuration will be used for the exercise'
	String get start_run_tip => 'The following configuration will be used for the exercise';

	/// en: 'The target mileage has not been reached yet. Do you want to stop the exercise?'
	String get stop_run_tip => 'The target mileage has not been reached yet. Do you want to stop the exercise?';

	/// en: 'Failed to obtain statistics. Please check if the VPN connection is established.'
	String get failed_to_get_stats => 'Failed to obtain statistics. Please check if the VPN connection is established.';

	/// en: 'The portal account of the current user is not logged in.'
	String get portal_user_not_login => 'The portal account of the current user is not logged in.';

	/// en: 'Total'
	String get total_count => 'Total';

	/// en: 'Run'
	String get run_count => 'Run';

	/// en: 'Other'
	String get other_count => 'Other';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app_name' => 'Punklorde',
			'common.setting' => 'Setting',
			'common.common' => 'Common',
			'common.account' => 'Account',
			'common.sources' => 'Sources',
			'common.unify_id' => 'Unify ID',
			'common.studnet_id' => 'Student ID',
			'common.name' => 'Name',
			'common.password' => 'Password',
			'common.scan_qrcode' => 'Scan',
			'common.binary' => 'Binary',
			'common.success' => 'Success',
			'common.failed' => 'Failed',
			'page.home' => 'Home',
			'page.schedule' => 'Schedule',
			'page.notification' => 'Notice',
			'page.profile' => 'Profile',
			'notice.cancel' => 'Cancel',
			'notice.confirm' => 'Confirm',
			'notice.login' => 'Login',
			'notice.search_school' => 'Search for schools by name...',
			'notice.search_platform' => 'Search for platforms by name...',
			'notice.search_user' => 'Search for users by name...',
			'notice.no_search_result' => 'No results meet the filtering criteria',
			'notice.location_service_failed' => 'Failed to start location service',
			'notice.location_service_failed_msg' => 'This will affect some functions, please check if the location permission is authorized.',
			'notice.no_avaliable_plat' => 'There is no available platform at this school.',
			'notice.no_guest' => 'There is no guest account.',
			'notice.login_success' => 'Login successfully',
			'notice.login_failed' => 'Login failed',
			'notice.refresh_success' => 'Login status refreshed successfully',
			'notice.refresh_failed' => 'Failed to refresh login status',
			'notice.refresh_failed_hint' => 'Manual re-login may be required.',
			'notice.not_login' => 'Not logged in',
			'notice.logged_in' => 'Logged in',
			'notice.unselected_user' => 'Unselected user.',
			'notice.wait_reource_load' => 'Wait for the resources to load completely.',
			'notice.sport_start_failed' => 'Error occurred during the start of the sport.',
			'notice.loading' => 'Loading...',
			'notice.invalid_qr_code' => 'Invalid code',
			'notice.multi_codes_select' => 'Multiple codes have been identified. Please select one to open.',
			'notice.continue_scan' => 'Continue scanning',
			'notice.open_code_hint' => 'How would you like to open this code?',
			'notice.err_guest_exist' => 'Guest accounts with the same ID already exist.',
			'notice.current_guest_exist' => 'This guest already exists.',
			'notice.not_support_plat' => 'The current school does not support the platform associated with this account.',
			'notice.invalid_data' => 'Invalid data',
			'notice.not_impl_schedule_service' => 'This school has not implemented the schedule service.',
			'notice.never_updated' => 'Never updated',
			'notice.failed_get_data' => 'Failed to obtain data',
			'notice.schedule_empty' => 'There are no classes today ~',
			'notice.phone_num_empty_hint' => 'Phone number cannot be blank',
			'notice.ver_code_empty_hint' => 'Verification code cannot be blank',
			'notice.pwd_empty_hint' => 'Password cannot be blank',
			'notice.share_qr_render_error' => 'QR code generation failed. Please use file sharing instead.',
			'notice.share_failed' => 'Share failed',
			'notice.failed_open_file' => 'Failed to open file',
			'notice.checkin_code_hint' => 'Please enter the check-in code',
			'title.id' => 'ID',
			'title.user' => 'User',
			'title.platform' => 'Platform',
			'title.phone_num' => 'Phone number',
			'title.verification_code' => 'Verification code',
			'title.exprire_at' => 'Expires at',
			'title.select_school' => 'Select School',
			'title.change_school' => 'Change School',
			'title.login_to' => 'Login to',
			'title.already_login' => 'Already logged into',
			'title.unknown_platform' => 'Unknown Platform',
			'title.select_platform' => 'Select Platform',
			'title.scan_result' => 'Scanning results',
			'title.add_guest' => 'Add Guest Account',
			'title.select_checkin_user' => 'Select the Users',
			'title.select_checkin_user_hine' => 'These users will be used for checking in.',
			'title.checkin_result' => 'Check-in Result',
			'title.week_title' => ({required Object week}) => 'Week ${week}',
			'title.teacher' => 'Teacher',
			'title.location' => 'Location',
			'title.time' => 'Time',
			'title.exam_position' => 'Seat',
			'title.class_id' => 'Class',
			'title.course_id' => 'Course',
			'title.last_update' => 'Last update',
			'title.student_list' => 'Students List',
			'title.select_login_method' => 'Select the login method',
			'title.use_ios_ua' => 'Use iOS UA',
			'title.checkin_code' => 'Check-in Code',
			'action.back' => 'Back',
			'action.refresh_login' => 'Refresh the login status',
			'action.refresh_schedule' => 'Refresh schedule',
			'action.logout' => 'Logout',
			'action.re_login' => 'Re-login',
			'action.login_info' => 'Login Information',
			'action.share_code' => 'Share Code',
			'action.file_sharing' => 'Using file sharing',
			'action.send_sms_code' => 'Send SMS Code',
			'action.pwd_login' => 'Password Login',
			'action.sms_login' => 'SMS Login',
			'action.copy' => 'Copy',
			'action.paste' => 'Paste',
			'action.open_with' => 'Open with...',
			'action.open_with_name' => ({required Object name}) => 'Open with ${name}',
			'action.add_guest' => 'Add guest account',
			'action.re_add_guest' => 'Re-add guest account',
			'action.check_stu_list' => 'Check students list',
			'action.guest_add_by_login' => 'Add by login',
			'action.guest_add_by_code' => 'Add from share code',
			'action.guest_add_by_file' => 'Add from share file',
			'action.manual_select_point' => 'Manually select check-in point',
			'label.primary' => 'Primary',
			'label.guest' => 'Guest',
			'label.expired' => 'Expired',
			'label.calender_mon' => 'Mon.',
			'label.calender_tue' => 'Tue.',
			'label.calender_wed' => 'Wed.',
			'label.calender_thu' => 'Thu.',
			'label.calender_fri' => 'Fri.',
			'label.calender_sat' => 'Sat.',
			'label.calender_sun' => 'Sun.',
			'label.current_week' => 'Current',
			'label.exam' => 'Exam',
			'label.ongoing' => 'Ongoing',
			'label.upcoming' => 'Upcoming',
			'label.deadline' => 'Deadline',
			'feat.all_function' => 'All Features',
			'feat.schedule' => 'Schedule',
			'feat.workspace' => 'Workspace',
			'setting.about' => 'About',
			'setting.theme' => 'Theme',
			'setting.primary_account' => 'Primary Account',
			'setting.guest_account' => 'Guest Account',
			'setting.add_account' => 'Add Account',
			'setting.password_vault' => 'Password Vault',
			'setting.dl_cache' => 'Download Cache',
			'setting.sources_list' => 'Sources List',
			'setting.github_link' => 'Github',
			'submodule.cqupt_checkin.title_check_in' => 'Check-in',
			'submodule.cqupt_checkin.check_in' => 'Check in',
			'submodule.cqupt_checkin.scan_checkin' => 'Scan',
			'submodule.cqupt_checkin.qrcode_checkin' => 'QR Code Check-in',
			'submodule.cqupt_checkin.radar_checkin' => 'Radar Check-in',
			'submodule.cqupt_checkin.pos_checkin' => 'Position Check-in',
			'submodule.cqupt_checkin.pin_checkin' => 'Pin Check-in',
			'submodule.cqupt_checkin.gesture_checkin' => 'Gesture Check-in',
			'submodule.cqupt_checkin.unsupported_checkin' => 'Unsupported Check-in',
			'submodule.cqupt_checkin.checkin_history' => 'Check-in History',
			'submodule.cqupt_checkin.checkin_all_success' => 'Check-in Successful',
			'submodule.cqupt_checkin.checkin_all_failed' => 'Check-in Failed',
			'submodule.cqupt_checkin.checkin_partial_failed' => 'Partial Check-in Successful',
			'submodule.cqupt_checkin.checkin_fatal_error' => 'A fatal error occurred, and the check-in failed.',
			'submodule.cqupt_checkin.retry_checkin' => 'Retry selected check-in',
			'submodule.cqupt_checkin.already_checkin' => 'Already checked in',
			'submodule.cqupt_checkin.no_ongoing_checkin' => 'No ongoing check-in process',
			'submodule.cqupt_checkin.pin_crack_checkin' => 'Brute force check-in',
			'submodule.cqupt_checkin.checkin_use_current_loc' => 'Current Location',
			'submodule.cqupt_checkin.checkin_use_auto_loc' => 'Auto-Obtain Location',
			'submodule.cqupt_sport.record' => 'Record',
			'submodule.cqupt_sport.configure' => 'Configure',
			'submodule.cqupt_sport.motion_profile' => 'Motion Profile',
			'submodule.cqupt_sport.start' => 'Start',
			'submodule.cqupt_sport.stop' => 'Stop',
			'submodule.cqupt_sport.locate' => 'Locate',
			'submodule.cqupt_sport.account' => 'Account',
			'submodule.cqupt_sport.progress' => 'Progress',
			'submodule.cqupt_sport.remain_time' => 'Remain',
			'submodule.cqupt_sport.target_distance' => 'Target',
			'submodule.cqupt_sport.speed' => 'Speed',
			'submodule.cqupt_sport.elapsed_time' => 'Elapsed Time',
			'submodule.cqupt_sport.distance' => 'Distance',
			'submodule.cqupt_sport.pace' => 'Pace',
			'submodule.cqupt_sport.jitter_seed' => 'Jitter Seed',
			'submodule.cqupt_sport.jitter_speed' => 'Speed Jitter Amplitude',
			'submodule.cqupt_sport.jitter_pos' => 'Position Jitter Amplitude',
			'submodule.cqupt_sport.update_interval' => 'Update Interval',
			'submodule.cqupt_sport.cfg_distance_hint' => 'In meters. It is recommended to be 100 meters or more above the actual target',
			'submodule.cqupt_sport.cfg_speed_hint' => 'In m/s. It is recommended to be around 3 (approximately 5′40″ pace)',
			'submodule.cqupt_sport.cfg_speed_jitter_hint' => 'In m/s. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking',
			'submodule.cqupt_sport.cfg_pos_jitter_hint' => 'In meters. The higher the value, the more obvious the jitter. It can effectively avoid water meter checking',
			'submodule.cqupt_sport.cfg_jitter_seed_hint' => 'Can be empty. The default is to use the timestamp',
			'submodule.cqupt_sport.input_invalid_hint' => 'Please enter the correct value.',
			'submodule.cqupt_sport.openid' => 'Open ID',
			'submodule.cqupt_sport.openid_hint' => 'Please enter the Open ID obtained by capturing data from the WeChat mini-program.',
			'submodule.cqupt_sport.choose_mode' => 'Choose Running Mode',
			'submodule.cqupt_sport.mode_auto_run' => 'Automatic Running',
			'submodule.cqupt_sport.mode_normal_run' => 'Normal Running',
			'submodule.cqupt_sport.mode_traj_record' => 'Trajectory Recording',
			'submodule.cqupt_sport.mode_auto_run_tip' => 'Using a motion simulator for automatic running.',
			'submodule.cqupt_sport.mode_normal_run_tip' => 'I\'ll run by myself.',
			'submodule.cqupt_sport.mode_traj_record_tip' => 'Records the movement trajectory but does not upload the data.',
			'submodule.cqupt_sport.tip_need_stop' => 'Please stop the running before exiting.',
			'submodule.cqupt_sport.disabled_by_perm' => 'DISABLED. Requires permission.',
			'submodule.cqupt_sport.select_user' => 'Select a User',
			'submodule.cqupt_sport.select_user_hint' => 'This user\'s information will be used for running.',
			'submodule.cqupt_sport.valid' => 'Valid',
			'submodule.cqupt_sport.invalid' => 'Invalid',
			'submodule.cqupt_sport.sport_type_run' => 'Running',
			'submodule.cqupt_sport.sport_type_other' => 'Other',
			'submodule.cqupt_sport.sport_exam' => 'Exam',
			'submodule.cqupt_sport.sport_addition' => 'Addition',
			'submodule.cqupt_sport.appealable' => 'Appealable',
			'submodule.cqupt_sport.appeal_success' => 'Appeal Successful',
			'submodule.cqupt_sport.appeal_failed' => 'Appeal Failed',
			'submodule.cqupt_sport.start_run' => 'Start Running',
			'submodule.cqupt_sport.stop_run' => 'Stop Running',
			'submodule.cqupt_sport.start_run_tip' => 'The following configuration will be used for the exercise',
			'submodule.cqupt_sport.stop_run_tip' => 'The target mileage has not been reached yet. Do you want to stop the exercise?',
			'submodule.cqupt_sport.failed_to_get_stats' => 'Failed to obtain statistics. Please check if the VPN connection is established.',
			'submodule.cqupt_sport.portal_user_not_login' => 'The portal account of the current user is not logged in.',
			'submodule.cqupt_sport.total_count' => 'Total',
			'submodule.cqupt_sport.run_count' => 'Run',
			'submodule.cqupt_sport.other_count' => 'Other',
			_ => null,
		};
	}
}
