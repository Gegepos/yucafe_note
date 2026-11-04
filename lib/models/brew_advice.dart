class BrewAdvice {
  final int? id;
  final int beanId;
  final String? beanName;

  /// ai = 大模型生成，rule = 规则回退
  final String source;
  final String? model;
  final double weight;
  final String brewingDevices;
  final String brewRatio;
  final String waterTemperature;
  final String grinder;
  final String grinderSize;
  final String? brewRecipe;
  final String? reason;
  final bool fellBack;
  final int? promptTokens;
  final int? completionTokens;
  final String? createTime;

  BrewAdvice({
    this.id,
    required this.beanId,
    this.beanName,
    required this.source,
    this.model,
    required this.weight,
    required this.brewingDevices,
    required this.brewRatio,
    required this.waterTemperature,
    required this.grinder,
    required this.grinderSize,
    this.brewRecipe,
    this.reason,
    this.fellBack = false,
    this.promptTokens,
    this.completionTokens,
    this.createTime,
  });

  bool get isAi => source == 'ai';

  factory BrewAdvice.fromJson(Map<String, dynamic> json) {
    return BrewAdvice(
      id: json['id'],
      beanId: json['beanId'] ?? 0,
      beanName: json['beanName'],
      source: json['source'] ?? 'rule',
      model: json['model'],
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      brewingDevices: json['brewingDevices'] ?? '',
      brewRatio: json['brewRatio'] ?? '',
      waterTemperature: json['waterTemperature'] ?? '',
      grinder: json['grinder'] ?? '',
      grinderSize: json['grinderSize'] ?? '',
      brewRecipe: json['brewRecipe'],
      reason: json['reason'],
      fellBack: json['fellBack'] == true,
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
      createTime: json['createTime']?.toString(),
    );
  }
}
