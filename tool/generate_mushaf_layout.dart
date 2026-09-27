// Generates assets/quran/mushaf_layout.json — the Madina Mushaf (QCF V1)
// 15-line layout for all 604 pages, from the quran.com API.
//
// Run from the project root:  dart run tool/generate_mushaf_layout.dart
//
// Output format:
// {
//   "chapters": [[id, nameArabic, startPage, revelationPlace, versesCount]],
//   "pages": [{"j": juz, "l": [line...]}]            // index 0 = page 1
// }
// line = {"w": [[glyph, surah, ayah, isEnd]]}   words line
//      | {"h": surah}                          surah name frame
//      | {"b": 1}                              bismillah
import 'dart:convert';
import 'dart:io';

const _api = 'https://api.quran.com/api/v4';
const _totalPages = 604;
const _concurrency = 8;

final _client = HttpClient();

Future<Map<String, dynamic>> _getJson(String url) async {
  for (var attempt = 1;; attempt++) {
    try {
      final request = await _client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      if (attempt >= 4) rethrow;
      stderr.writeln('retry $attempt: $url ($e)');
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }
}

class _Word {
  _Word(this.code, this.surah, this.ayah, this.isEnd, this.line);
  final String code;
  final int surah;
  final int ayah;
  final bool isEnd;
  final int line;
}

Future<List<_Word>> _fetchPageWords(int page) async {
  final json = await _getJson(
    '$_api/verses/by_page/$page?words=true&per_page=50'
    '&word_fields=code_v1,line_number,page_number&fields=juz_number',
  );
  final words = <_Word>[];
  for (final verse in json['verses'] as List) {
    final key = (verse['verse_key'] as String).split(':');
    final surah = int.parse(key[0]);
    final ayah = int.parse(key[1]);
    for (final word in verse['words'] as List) {
      words.add(_Word(
        word['code_v1'] as String,
        surah,
        ayah,
        word['char_type_name'] == 'end',
        word['line_number'] as int,
      ));
    }
  }
  _pageJuz[page] = (json['verses'] as List).first['juz_number'] as int;
  return words;
}

final _pageJuz = <int, int>{};

Future<void> main() async {
  final chaptersJson = await _getJson('$_api/chapters?language=ar');
  final chapters = <List<Object>>[];
  final bismillahPre = <int, bool>{};
  for (final c in chaptersJson['chapters'] as List) {
    final id = c['id'] as int;
    bismillahPre[id] = c['bismillah_pre'] as bool;
    chapters.add([
      id,
      c['name_arabic'] as String,
      (c['pages'] as List).first as int,
      c['revelation_place'] as String,
      c['verses_count'] as int,
    ]);
  }

  final pageWords = List<List<_Word>>.filled(_totalPages, const []);
  var next = 1;
  Future<void> worker() async {
    while (next <= _totalPages) {
      final page = next++;
      pageWords[page - 1] = await _fetchPageWords(page);
      if (page % 50 == 0) stdout.writeln('fetched page $page');
    }
  }

  await Future.wait(List.generate(_concurrency, (_) => worker()));

  final pages = <Map<String, Object>>[];
  for (var p = 1; p <= _totalPages; p++) {
    final words = pageWords[p - 1];
    final maxLine = p <= 2 ? 8 : 15;
    final byLine = <int, List<_Word>>{};
    for (final w in words) {
      byLine.putIfAbsent(w.line, () => []).add(w);
    }

    final lines = <Map<String, Object>>[];
    var n = 1;
    while (n <= maxLine) {
      if (byLine.containsKey(n)) {
        lines.add({
          'w': [
            for (final w in byLine[n]!)
              [w.code, w.surah, w.ayah, w.isEnd ? 1 : 0]
          ],
        });
        n++;
        continue;
      }
      // A run of empty lines holds the frame (+ bismillah) of the next surah.
      final start = n;
      while (n <= maxLine && !byLine.containsKey(n)) {
        n++;
      }
      final runLength = n - start;
      final atPageEnd = n > maxLine;
      final nextSurah = atPageEnd
          ? pageWords[p].first.surah // p < 604 here: page 604 ends with words
          : byLine[n]!.first.surah;
      final hasBismillah = bismillahPre[nextSurah] ?? false;
      final elements = <Map<String, Object>>[
        {'h': nextSurah},
        if (hasBismillah) {'b': 1},
      ];
      // A split frame/bismillah pair: frame at the page end, bismillah at the
      // start of the next page.
      final picked = runLength >= elements.length
          ? elements
          : atPageEnd
              ? elements.sublist(0, runLength)
              : elements.sublist(elements.length - runLength);
      lines.addAll(picked);
      if (runLength != picked.length) {
        stderr.writeln('page $p: empty run of $runLength at line $start');
      }
    }
    pages.add({'j': _pageJuz[p]!, 'l': lines});
  }

  final out = File('assets/quran/mushaf_layout.json');
  await out.parent.create(recursive: true);
  await out.writeAsString(jsonEncode({'chapters': chapters, 'pages': pages}));
  stdout.writeln('wrote ${out.path} (${(await out.length()) ~/ 1024} KB)');
  _client.close();
}
