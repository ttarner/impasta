class Preset {
  final int? id;
  final String name;
  final DateTime createdAt;
  final String? notes;
  final int waterPerc;
  final double oilPerc;
  final double saltPerc;
  final double yeastPerc;
  final String yeastType; // 'fresh' or 'dry'
  final double impastoRatio;
  final List<String> mediaPaths;

  Preset({
    this.id,
    required this.name,
    required this.createdAt,
    this.notes,
    required this.waterPerc,
    required this.oilPerc,
    required this.saltPerc,
    required this.yeastPerc,
    this.yeastType = 'fresh',
    required this.impastoRatio,
    this.mediaPaths = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'waterPerc': waterPerc,
        'oilPerc': oilPerc,
        'saltPerc': saltPerc,
        'yeastPerc': yeastPerc,
        'yeastType': yeastType,
        'impastoRatio': impastoRatio,
        'mediaPaths': mediaPaths,
      };

  factory Preset.fromMap(Map<String, dynamic> map, int id) => Preset(
        id: id,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        notes: map['notes'] as String?,
        waterPerc: map['waterPerc'] as int,
        oilPerc: (map['oilPerc'] as num).toDouble(),
        saltPerc: (map['saltPerc'] as num).toDouble(),
        yeastPerc: (map['yeastPerc'] as num).toDouble(),
        yeastType: map['yeastType'] as String? ?? 'fresh',
        impastoRatio: (map['impastoRatio'] as num).toDouble(),
        mediaPaths: List<String>.from(map['mediaPaths'] ?? []),
      );

  Preset copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? notes,
    int? waterPerc,
    double? oilPerc,
    double? saltPerc,
    double? yeastPerc,
    String? yeastType,
    double? impastoRatio,
    List<String>? mediaPaths,
  }) =>
      Preset(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        notes: notes ?? this.notes,
        waterPerc: waterPerc ?? this.waterPerc,
        oilPerc: oilPerc ?? this.oilPerc,
        saltPerc: saltPerc ?? this.saltPerc,
        yeastPerc: yeastPerc ?? this.yeastPerc,
        yeastType: yeastType ?? this.yeastType,
        impastoRatio: impastoRatio ?? this.impastoRatio,
        mediaPaths: mediaPaths ?? this.mediaPaths,
      );
}
