class HadithMatnModel {
  final int id;
  final String name;
  final int hadithsCount;

  const HadithMatnModel({
    required this.id,
    required this.name,
    required this.hadithsCount,
  });

  factory HadithMatnModel.fromJson(Map<String, dynamic> json) {
    return HadithMatnModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      hadithsCount: json['hadithsCount'] as int? ?? 0,
    );
  }
}
