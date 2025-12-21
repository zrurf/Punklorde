import 'package:punklorde/common/models/auth.dart';

class SchoolModel {
  final String id;
  final String name;

  final List<AccountProvider> accountProviders;
  final String logoUri;
  final String bannerUri;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.accountProviders,
    required this.logoUri,
    required this.bannerUri,
  });
}
