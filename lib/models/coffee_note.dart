class CoffeeNote {
  final int? id;
  final int beanId;
  final String? beanName;
  final String? beanBrand;
  final double weight;
  final String brewingDevices;
  final String brewRatio;
  final String waterTemperature;
  final String grinder;
  final String grinderSize;
  final String? brewRecipe;
  final int times;
  final String? createTime;
  final String? editTime;

  CoffeeNote({
    this.id,
    required this.beanId,
    this.beanName,
    this.beanBrand,
    required this.weight,
    required this.brewingDevices,
    required this.brewRatio,
    required this.waterTemperature,
    required this.grinder,
    required this.grinderSize,
    this.brewRecipe,
    this.times = 0,
    this.createTime,
    this.editTime,
  });

  factory CoffeeNote.fromJson(Map<String, dynamic> json) {
    return CoffeeNote(
      id: json['id'],
      beanId: json['beanId'] ?? 0,
      beanName: json['beanName'],
      beanBrand: json['beanBrand'],
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      brewingDevices: json['brewingDevices'] ?? '',
      brewRatio: json['brewRatio'] ?? '',
      waterTemperature: json['waterTemperature'] ?? '',
      grinder: json['grinder'] ?? '',
      grinderSize: json['grinderSize'] ?? '',
      brewRecipe: json['brewRecipe'],
      times: json['times'] ?? 0,
      createTime: json['createTime']?.toString(),
      editTime: json['editTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'beanId': beanId,
        'weight': weight,
        'brewingDevices': brewingDevices,
        'brewRatio': brewRatio,
        'waterTemperature': waterTemperature,
        'grinder': grinder,
        'grinderSize': grinderSize,
        'brewRecipe': brewRecipe,
      };
}
