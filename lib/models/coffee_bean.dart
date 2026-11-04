class CoffeeBean {
  final int? id;
  final String? image;
  final String name;
  final String? brand;
  final String? varieties;
  final String? altitude;
  final String country;
  final String roastDate;
  final String roastLevel;
  final String process;
  final String? area;
  final String? productArea;
  final String? estate;
  final String? lot;
  final String? waterContent;
  final String? density;
  final String? waterActivity;
  final double? agtron;
  final double? powder;
  final int? overallPersonalScores;
  final String? flavors;
  final double? cuppingScores;
  final double stock;
  final double? greenPrice;
  final double? roastedPrice;
  final String? remark;
  final String? createTime;
  final String? editTime;

  CoffeeBean({
    this.id,
    this.image,
    required this.name,
    this.brand,
    this.varieties,
    this.altitude,
    required this.country,
    required this.roastDate,
    required this.roastLevel,
    required this.process,
    this.area,
    this.productArea,
    this.estate,
    this.lot,
    this.waterContent,
    this.density,
    this.waterActivity,
    this.agtron,
    this.powder,
    this.overallPersonalScores,
    this.flavors,
    this.cuppingScores,
    this.stock = 0,
    this.greenPrice,
    this.roastedPrice,
    this.remark,
    this.createTime,
    this.editTime,
  });

  factory CoffeeBean.fromJson(Map<String, dynamic> json) {
    return CoffeeBean(
      id: json['id'],
      image: json['image'],
      name: json['name'] ?? '',
      brand: json['brand'],
      varieties: json['varieties'],
      altitude: json['altitude'],
      country: json['country'] ?? '',
      roastDate: json['roastDate']?.toString() ?? '',
      roastLevel: json['roastLevel'] ?? '',
      process: json['process'] ?? '',
      area: json['area'],
      productArea: json['productArea'],
      estate: json['estate'],
      lot: json['lot'],
      waterContent: json['waterContent'],
      density: json['density'],
      waterActivity: json['waterActivity'],
      agtron: (json['agtron'] as num?)?.toDouble(),
      powder: (json['powder'] as num?)?.toDouble(),
      overallPersonalScores: json['overallPersonalScores'],
      flavors: json['flavors'],
      cuppingScores: (json['cuppingScores'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      greenPrice: (json['greenPrice'] as num?)?.toDouble(),
      roastedPrice: (json['roastedPrice'] as num?)?.toDouble(),
      remark: json['remark'],
      createTime: json['createTime']?.toString(),
      editTime: json['editTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'image': image,
        'name': name,
        'brand': brand,
        'varieties': varieties,
        'altitude': altitude,
        'country': country,
        'roastDate': roastDate,
        'roastLevel': roastLevel,
        'process': process,
        'area': area,
        'productArea': productArea,
        'estate': estate,
        'lot': lot,
        'waterContent': waterContent,
        'density': density,
        'waterActivity': waterActivity,
        'agtron': agtron,
        'powder': powder,
        'overallPersonalScores': overallPersonalScores,
        'flavors': flavors,
        'cuppingScores': cuppingScores,
        'stock': stock,
        'greenPrice': greenPrice,
        'roastedPrice': roastedPrice,
        'remark': remark,
      };
}
