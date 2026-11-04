class AiUsagePoint {
  final String date;
  final int promptTokens;
  final int completionTokens;
  final int calls;

  AiUsagePoint({
    required this.date,
    required this.promptTokens,
    required this.completionTokens,
    required this.calls,
  });

  int get total => promptTokens + completionTokens;

  /// 只保留 MM-dd，图表横轴用
  String get shortDate => date.length >= 10 ? date.substring(5) : date;

  factory AiUsagePoint.fromJson(Map<String, dynamic> json) {
    return AiUsagePoint(
      date: json['date']?.toString() ?? '',
      promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
      calls: (json['calls'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiUsage {
  final int days;
  final List<AiUsagePoint> points;
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final int totalTokens;
  final int totalCalls;

  AiUsage({
    required this.days,
    required this.points,
    required this.totalPromptTokens,
    required this.totalCompletionTokens,
    required this.totalTokens,
    required this.totalCalls,
  });

  static AiUsage empty() => AiUsage(
        days: 0,
        points: const [],
        totalPromptTokens: 0,
        totalCompletionTokens: 0,
        totalTokens: 0,
        totalCalls: 0,
      );

  factory AiUsage.fromJson(Map<String, dynamic> json) {
    final raw = (json['points'] as List?) ?? const [];
    return AiUsage(
      days: (json['days'] as num?)?.toInt() ?? 0,
      points: raw
          .map((e) => AiUsagePoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalPromptTokens: (json['totalPromptTokens'] as num?)?.toInt() ?? 0,
      totalCompletionTokens: (json['totalCompletionTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCalls: (json['totalCalls'] as num?)?.toInt() ?? 0,
    );
  }
}
