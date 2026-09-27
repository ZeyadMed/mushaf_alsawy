import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads, caches and registers the QCF V1 (Madina Mushaf) page fonts.
/// Each of the 604 pages has its own font; a page's glyph codes only render
/// with that page's font.
class QcfFontManager {
  QcfFontManager({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl =
      'https://static.qurancdn.com/fonts/quran/hafs/v1/ttf';

  final Dio _dio;
  final Map<int, Future<String>> _fonts = {};
  final Set<int> _loaded = {};
  Directory? _cacheDir;

  static String familyFor(int page) =>
      'QCF_P${page.toString().padLeft(3, '0')}';

  bool isLoaded(int page) => _loaded.contains(page);

  /// Makes the font of [page] available and returns its family name.
  Future<String> ensurePageFont(int page) {
    return _fonts[page] ??= _load(page).then((family) {
      _loaded.add(page);
      return family;
    }, onError: (Object error) {
      _fonts.remove(page);
      throw error;
    });
  }

  void prefetch(Iterable<int> pages) {
    for (final page in pages) {
      if (page >= 1 && page <= 604) ensurePageFont(page).ignore();
    }
  }

  Future<String> _load(int page) async {
    final family = familyFor(page);
    final file = File('${(await _dir()).path}/p$page.ttf');
    late final Uint8List bytes;
    if (await file.exists() && await file.length() > 0) {
      bytes = await file.readAsBytes();
    } else {
      final response = await _dio.get<List<int>>(
        '$_baseUrl/p$page.ttf',
        options: Options(responseType: ResponseType.bytes),
      );
      bytes = Uint8List.fromList(response.data!);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    }
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    return family;
  }

  Future<Directory> _dir() async {
    if (_cacheDir case final dir?) return dir;
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/qcf_v1');
    await dir.create(recursive: true);
    return _cacheDir = dir;
  }
}
