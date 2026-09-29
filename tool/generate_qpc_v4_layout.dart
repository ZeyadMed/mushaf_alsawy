// Swaps the glyphs of assets/quran/mushaf_layout.json for the QPC Hafs v4
// glyphs of assets/qpc-hafs-v4/quran-glyphs.json, keeping the Madina Mushaf
// line layout. Safe to re-run: codes are always taken from the v4 data.
//
// Run from the project root:  dart run tool/generate_qpc_v4_layout.dart
//
// Each word becomes [glyph, surah, ayah, isEnd, font], where `font` is the
// QCF4_Hafs_NN_W file (1–47) the glyph belongs to.
//
// v4 has one glyph per word, the layout one entry per word. Where v4 has one
// glyph more, the extra glyph is merged into a layout word:
//  - ۞ hizb marker: the first glyph, merged into the first word;
//  - ۩ sajda marker: the glyph before the end marker, merged into the last word;
//  - otherwise v4 splits a word the layout keeps whole (e.g. بَعۡدَمَا), which
//    is the one multi-codepoint word of that ayah.
import 'dart:convert';
import 'dart:io';

const _layoutPath = 'assets/quran/mushaf_layout.json';
const _glyphsPath = 'assets/qpc-hafs-v4/quran-glyphs.json';
const _textPath = 'assets/qpc-hafs-v4/quran.json';

/// Ayat with more than one multi-codepoint word: index of the split word.
const _splitOverrides = {'2:181': 2}; // بَعۡدَمَا

Future<void> main() async {
  final layout = jsonDecode(await File(_layoutPath).readAsString())
      as Map<String, dynamic>;
  final glyphs = <String, ({String text, int font})>{
    for (final a in (jsonDecode(await File(_glyphsPath).readAsString())
        as Map<String, dynamic>)['ayat'] as List)
      '${a['surah']}:${a['ayah']}': (
        text: [for (final c in a['chunks'] as List) c['text'] as String].join(),
        font: (a['chunks'] as List).first['p'] as int,
      ),
  };
  final text = <String, String>{
    for (final a in (jsonDecode(await File(_textPath).readAsString())
        as Map<String, dynamic>)['ayat'] as List)
      '${a['surah']}:${a['ayah']}': a['text'] as String,
  };

  // Layout words of each ayah, in reading order across lines and pages.
  final ayahWords = <String, List<List<dynamic>>>{};
  for (final page in layout['pages'] as List) {
    for (final line in page['l'] as List) {
      for (final word in (line['w'] as List?) ?? const []) {
        ayahWords.putIfAbsent('${word[1]}:${word[2]}', () => []).add(word);
      }
    }
  }

  var merged = 0;
  for (final MapEntry(key: key, value: words) in ayahWords.entries) {
    final g = glyphs[key]!;
    final codes = g.text.runes.map(String.fromCharCode).toList();
    final extra = codes.length - words.length;
    if (extra != 0 && extra != 1) {
      throw StateError(
          '$key: ${codes.length} glyphs for ${words.length} words');
    }
    if (extra == 1) {
      final at = _mergeIndex(key, words, text[key]!);
      codes.replaceRange(at, at + 2, [codes[at] + codes[at + 1]]);
      merged++;
    }
    for (final (i, word) in words.indexed) {
      word
        ..[0] = codes[i]
        ..length = 4
        ..add(g.font);
    }
  }

  await File(_layoutPath).writeAsString(jsonEncode(layout));
  stdout.writeln('wrote $_layoutPath: ${ayahWords.length} ayat, '
      '$merged with a merged glyph');
}

/// Index of the v4 glyph that is merged with the one after it.
int _mergeIndex(String key, List<List<dynamic>> words, String text) {
  if (text.trimLeft().startsWith('۞') &&
      (words.first[0] as String).length >= 2) {
    return 0;
  }
  if (text.contains('۩')) return words.length - 2;
  if (_splitOverrides[key] case final index?) return index;
  final multi = [
    for (final (i, w) in words.indexed)
      if (i < words.length - 1 && (w[0] as String).length >= 2) i,
  ];
  if (multi.length != 1) {
    throw StateError('$key: cannot place the extra glyph (candidates $multi)');
  }
  stdout.writeln('$key: split word ${multi.single}');
  return multi.single;
}
