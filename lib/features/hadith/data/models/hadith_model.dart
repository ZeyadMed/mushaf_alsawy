class HadithModel {
  final int id;
  final int matnId;
  final String matnName;
  final int number;
  final String text;
  final String? grade;
  final bool hasAudio;
  final String? audioUrl;

  const HadithModel({
    required this.id,
    required this.matnId,
    required this.matnName,
    required this.number,
    required this.text,
    required this.grade,
    required this.hasAudio,
    required this.audioUrl,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      matnId: (json['matnId'] as num?)?.toInt() ?? 0,
      matnName: json['matnName'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      grade: json['grade'] as String?,
      hasAudio: json['hasAudio'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String?,
    );
  }
}
