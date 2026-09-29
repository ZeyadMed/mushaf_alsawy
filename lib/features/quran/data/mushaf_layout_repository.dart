import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_alsawy/features/quran/data/models/mushaf_layout_model.dart';

/// Loads the bundled Madina Mushaf layout once and keeps it in memory.
class MushafLayoutRepository {
  static const int totalPages = 604;
  static const String _assetPath = 'assets/quran/mushaf_layout.json';

  MushafLayout? _layout;
  Future<MushafLayout>? _loading;

  MushafLayout? get layout => _layout;

  Future<MushafLayout> load() {
    if (_layout case final layout?) return Future.value(layout);
    return _loading ??= _read();
  }

  Future<MushafLayout> _read() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final layout = await compute(_parse, raw);
      _layout = layout;
      return layout;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static MushafLayout _parse(String raw) =>
      MushafLayout.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  MushafPage page(int number) => _layout!.pages[number - 1];

  MushafChapter chapter(int surah) => _layout!.chapters[surah - 1];

  int startPageOf(int surah) => chapter(surah).startPage;

  /// The QPC v4 fonts the words of [number] render with.
  Set<int> fontsOf(int number) => {
        for (final line in page(number).lines.whereType<MushafWordsLine>())
          for (final word in line.words) word.font,
      };

  /// The glyphs of ayah [surah]:[ayah] grouped by page (an ayah may run over
  /// onto the next page), searched around [nearPage].
  List<({int page, List<MushafWord> words})> ayahSegments(
      int surah, int ayah, int nearPage) {
    final segments = <({int page, List<MushafWord> words})>[];
    for (var p = nearPage - 1; p <= nearPage + 1; p++) {
      if (p < 1 || p > totalPages) continue;
      final words = [
        for (final line in page(p).lines.whereType<MushafWordsLine>())
          for (final w in line.words)
            if (w.surah == surah && w.ayah == ayah) w,
      ];
      if (words.isNotEmpty) segments.add((page: p, words: words));
    }
    return segments;
  }

  /// Glyphs of the bismillah as printed on page 1 (Al-Fatiha, ayah 1),
  /// without the ayah-number marker. Rendered with QPC v4 font 1.
  ///
  /// The glyphs are Private-Use codepoints, which bidi treats as LTR, so the
  /// string is wrapped in a right-to-left override.
  String get bismillahGlyphs {
    final line = page(1).lines.whereType<MushafWordsLine>().first;
    final words = line.words
        .where((w) => w.ayah == 1 && !w.isEnd)
        .map((w) => w.code)
        .join(' ');
    return '$rtlOverride$words$popDirectionalFormatting';
  }

  static const String rtlOverride = '\u202E';
  static const String popDirectionalFormatting = '\u202C';
}
