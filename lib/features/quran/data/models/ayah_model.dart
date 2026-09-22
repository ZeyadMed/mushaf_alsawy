class AyahModel {
  final int number;
  final String arabicText;
  final String tafsir;

  const AyahModel({
    required this.number,
    required this.arabicText,
    required this.tafsir,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      number: json['number'] as int? ?? 0,
      arabicText: (json['arabicText'] as String? ?? '').trim(),
      tafsir: json['tafsir'] as String? ?? '',
    );
  }
}
