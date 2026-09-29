import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads, caches and registers the QPC Hafs v4 (Madina Mushaf) fonts.
/// The glyphs are split over 47 font files of ~13 pages each; a word's glyph
/// only renders with its own font (see [MushafWord.font]).
class QcfFontManager {
  QcfFontManager({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl =
      'https://fonts.quran.ws/bundles/qpc-hafs-v4/font';
  static const int fontCount = 47;

  /// Font 1 is bundled (pubspec family `QCF4Hafs`), so page 1 and every
  /// bismillah render without a download.
  static const String _bundledFamily = 'QCF4Hafs';

  final Dio _dio;
  final Map<int, Future<String>> _fonts = {};
  final Set<int> _loaded = {1};
  Directory? _cacheDir;

  static String _fileName(int font) =>
      'QCF4_Hafs_${font.toString().padLeft(2, '0')}_W';

  static String familyFor(int font) =>
      font == 1 ? _bundledFamily : _fileName(font);

  bool isLoaded(int font) => _loaded.contains(font);

  /// Makes [font] available and returns its family name.
  Future<String> ensureFont(int font) {
    if (font == 1) return Future.value(_bundledFamily);
    return _fonts[font] ??= _load(font).then((family) {
      _loaded.add(font);
      return family;
    }, onError: (Object error) {
      _fonts.remove(font);
      throw error;
    });
  }

  void prefetch(Iterable<int> fonts) {
    for (final font in fonts) {
      if (font >= 1 && font <= fontCount) ensureFont(font).ignore();
    }
  }

  Future<String> _load(int font) async {
    final family = familyFor(font);
    final file = File('${(await _dir()).path}/${_fileName(font)}.ttf');
    late final Uint8List bytes;
    if (await file.exists() && await file.length() > 0) {
      bytes = await file.readAsBytes();
    } else {
      final response = await _dio.get<List<int>>(
        '$_baseUrl/${_fileName(font)}.ttf',
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
    final dir = Directory('${support.path}/qcf_v4');
    await dir.create(recursive: true);
    return _cacheDir = dir;
  }
}
