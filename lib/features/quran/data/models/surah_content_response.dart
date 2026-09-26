import 'ayah_model.dart';

class SurahContentResponse {
  const SurahContentResponse({required this.ayahs, this.audioUrl});

  final List<AyahModel> ayahs;
  final String? audioUrl;

  factory SurahContentResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    final contentMap = content is Map<String, dynamic> ? content : json;
    final rawAyahs = contentMap['data'];

    return SurahContentResponse(
      audioUrl: json['audioUrl'] as String?,
      ayahs: rawAyahs is List
          ? rawAyahs
              .whereType<Map<String, dynamic>>()
              .map(AyahModel.fromJson)
              .toList(growable: false)
          : const <AyahModel>[],
    );
  }
}