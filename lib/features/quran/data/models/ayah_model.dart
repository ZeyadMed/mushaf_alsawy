class AyahModel {
  final int number;
  final String arabicText;
  final String tafsir;
  final int? pageNumber;
  final int? juz;
  final int? hizbQuarter;
  final bool sajda;
  final int? surahNumber;
  final String? surahNameArabic;
  final int? ayahNumberInSurah;
  final bool? isFirstAyahOfSurah;

  const AyahModel({
    required this.number,
    required this.arabicText,
    required this.tafsir,
    this.pageNumber,
    this.juz,
    this.hizbQuarter,
    this.sajda = false,
    this.surahNumber,
    this.surahNameArabic,
    this.ayahNumberInSurah,
    this.isFirstAyahOfSurah,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      number: _toInt(json['number']) ?? 0,
      arabicText: (json['arabicText'] as String? ?? '').trim(),
      tafsir: json['tafsir'] as String? ?? '',
      pageNumber: _toInt(json['pageNumber']),
      juz: _toInt(json['juz']),
      hizbQuarter: _toInt(json['hizbQuarter']),
      sajda: _toBool(json['sajda']),
      surahNumber: _toInt(json['surahNumber']),
      surahNameArabic: json['surahNameArabic'] as String?,
      ayahNumberInSurah: _toInt(json['ayahNumberInSurah']),
      isFirstAyahOfSurah: json['isFirstAyahOfSurah'] == null
          ? null
          : _toBool(json['isFirstAyahOfSurah']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
