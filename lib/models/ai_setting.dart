class AiSetting {
  final bool configured;
  final String? maskedKey;
  final String model;
  final String? updatedAt;

  AiSetting({
    required this.configured,
    this.maskedKey,
    required this.model,
    this.updatedAt,
  });

  /// 只有接入自己的 Key 才能用 AI 推荐（服务器不提供默认 Key）
  bool get available => configured;

  String get statusText {
    if (configured) return '已接入：${maskedKey ?? "-"}';
    return '未接入，AI 推荐不可用';
  }

  factory AiSetting.fromJson(Map<String, dynamic> json) {
    return AiSetting(
      configured: json['configured'] == true,
      maskedKey: json['maskedKey'],
      model: json['model'] ?? 'deepseek-chat',
      updatedAt: json['updatedAt'],
    );
  }
}
