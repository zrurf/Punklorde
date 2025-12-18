class UploadPointRedult {
  final num timeConsuming;
  final num mileage;
  final num expiredCountInForbiddenArea;

  const UploadPointRedult({
    required this.timeConsuming,
    required this.mileage,
    required this.expiredCountInForbiddenArea,
  });

  factory UploadPointRedult.fromJson(Map<String, dynamic> json) {
    return UploadPointRedult(
      timeConsuming: json['timeConsuming'],
      mileage: json['mileage'],
      expiredCountInForbiddenArea: json['expiredCountInForbiddenArea'],
    );
  }
}
