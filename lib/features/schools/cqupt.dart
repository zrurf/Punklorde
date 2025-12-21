import 'package:punklorde/common/models/school.dart';
import 'package:punklorde/features/accounts/cqupt/tongtian.dart';

final schoolCqupt = SchoolModel(
  id: "cqupt",
  name: "重庆邮电大学",
  accountProviders: [TongtianAuthProvider()],
  logoUri: 'assets/images/logo/cqupt.png',
  bannerUri: 'assets/images/banner/cqupt_1.jpg',
);
