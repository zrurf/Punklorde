// 运动规则接口返回结果
class SportRuleResult {
  final num maxPace;
  final num minPace;

  const SportRuleResult({required this.maxPace, required this.minPace});

  factory SportRuleResult.fromJson(Map<String, dynamic> json) {
    return SportRuleResult(maxPace: json['maxPace'], minPace: json['minPace']);
  }
}
