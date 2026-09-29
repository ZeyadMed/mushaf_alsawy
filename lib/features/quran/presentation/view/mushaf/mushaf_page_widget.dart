import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/helpers/arabic_digits.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/mushaf_layout_model.dart';
import 'package:mushaf_alsawy/features/quran/data/mushaf_layout_repository.dart';
import 'package:mushaf_alsawy/features/quran/data/qcf_font_manager.dart';

const Color mushafInkColor = Color(0xff1b1b1b);
const Color mushafFrameColor = Color(0xff8a6d3b);
const Color mushafAyahMarkerColor = Color(0xffb8413f);
const Color _highlightColor = Color(0x33c9a24a);

// Madina Mushaf print colours.
const Color _frameInk = Color(0xff3d4f5c);
const Color _frameRed = Color(0xffc4585a);
const Color _framePink = Color(0xfff4cdc6);
const Color _frameLight = Color(0xfffdf6f2);
const Color _cream = Color(0xfffdfaf0);

/// QPC v4 glyphs keep their natural width (the print justifies with spacing),
/// so each page is sized to its widest justified line, within these bounds;
/// a line wider than the upper bound is scaled down on its own.
const double _minLineWidthInEm = 15.5;
const double _maxLineWidthInEm = 19;
const double _minLineHeightInEm = 1.45;
const int _linesPerPage = 15;

String arabicJuzName(int juz) {
  const names = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];
  return juz >= 1 && juz <= names.length ? names[juz - 1] : arabicDigits(juz);
}

/// Calligraphic "سورة …" glyph of [surah] in the `SurahNameV4` font
/// (assets/fonts/surah-name-v4-color.ttf). The font lists surahs 22–114
/// first, then 1–21, on these codepoints.
String surahNameGlyph(int surah) {
  const codes = [
    0xfb51, 0xfb52, 0xfb54, 0xfb55, 0xfb57, 0xfb58, 0xfb5a, 0xfb5b, 0xfb5d, //
    0xfb5e, 0xfb60, 0xfb61, 0xfb63, 0xfb64, 0xfb66, 0xfb67, 0xfb69, 0xfb6a,
    0xfb6c, 0xfb6d, 0xfb6f, 0xfb70, 0xfb72, 0xfb73, 0xfb75, 0xfb76, 0xfb78,
    0xfb79, 0xfb7b, 0xfb7c, 0xfb7e, 0xfb7f, 0xfb81, 0xfb82, 0xfb84, 0xfb85,
    0xfb87, 0xfb88, 0xfb8a, 0xfb8b, 0xfb8d, 0xfb8e, 0xfb90, 0xfb91, 0xfb93,
    0xfb94, 0xfb96, 0xfb97, 0xfb99, 0xfb9a, 0xfb9c, 0xfb9d, 0xfb9f, 0xfba0,
    0xfba2, 0xfba3, 0xfba5, 0xfba6, 0xfba8, 0xfba9, 0xfbab, 0xfbac, 0xfbae,
    0xfbaf, 0xfbb1, 0xfbb2, 0xfbb4, 0xfbb5, 0xfbb7, 0xfbb8, 0xfbba, 0xfbbb,
    0xfbbd, 0xfbbe, 0xfbc0, 0xfbc1, 0xfbd3, 0xfbd4, 0xfbd6, 0xfbd7, 0xfbd9,
    0xfbda, 0xfbdc, 0xfbdd, 0xfbdf, 0xfbe0, 0xfbe2, 0xfbe3, 0xfbe5, 0xfbe6,
    0xfbe8, 0xfbe9, 0xfbeb, 0xfc45, 0xfc46, 0xfc47, 0xfc4a, 0xfc4b, 0xfc4e,
    0xfc4f, 0xfc51, 0xfc52, 0xfc53, 0xfc55, 0xfc56, 0xfc58, 0xfc5a, 0xfc5b,
    0xfc5c, 0xfc5d, 0xfc5e, 0xfc61, 0xfc62, 0xfc64,
  ];
  return String.fromCharCode(codes[surah >= 22 ? surah - 22 : surah + 92]);
}

/// One page of the Madina Mushaf: 15 lines of QPC v4 glyphs in the printed
/// frame.
class MushafPageWidget extends StatefulWidget {
  const MushafPageWidget({
    required this.page,
    required this.selectedAyah,
    required this.onAyahTap,
    super.key,
  });

  final MushafPage page;
  final ValueNotifier<String?> selectedAyah;
  final void Function(MushafWord word, MushafPage page) onAyahTap;

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  final _fonts = getIt<QcfFontManager>();
  final _repo = getIt<MushafLayoutRepository>();
  late Future<void> _fontsReady;

  /// Natural width (in em) of each words line, measured once fonts load.
  Map<MushafWordsLine, double>? _lineWidths;

  Set<int> get _pageFonts => _repo.fontsOf(widget.page.number);

  @override
  void initState() {
    super.initState();
    _fontsReady = _loadFonts();
  }

  // Bismillah lines use font 1, which is bundled.
  Future<void> _loadFonts() => Future.wait(_pageFonts.map(_fonts.ensureFont));

  bool get _fontsLoaded => _pageFonts.every(_fonts.isLoaded);

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final chapter = _repo.chapter(page.firstSurah);
    final band = 13.w;
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
      child: Column(
        children: [
          _PageHeader(surahName: chapter.name, juz: page.juz),
          SizedBox(height: 3.h),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MushafFramePainter(band)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    band + 9.w,
                    band + 6.h,
                    band + 9.w,
                    band + 10.h,
                  ),
                  child: FutureBuilder<void>(
                    future: _fontsReady,
                    builder: (context, snapshot) {
                      if (_fontsLoaded) return _buildLines();
                      if (snapshot.hasError) {
                        return _FontError(
                          onRetry: () =>
                              setState(() => _fontsReady = _loadFonts()),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _PageNumberMedallion(
                    number: page.number,
                    height: band * 1.9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<MushafWordsLine, double> _measureLines() {
    return _lineWidths ??= {
      for (final line in widget.page.lines.whereType<MushafWordsLine>())
        line: _naturalWidth(line, 100) / 100,
    };
  }

  Widget _buildLines() {
    final page = widget.page;
    final widths = _measureLines();
    bool isShort(MushafWordsLine line) {
      if (page.isCentered) return true;
      final last = line.words.last;
      final endsSurah =
          last.isEnd && last.ayah == _repo.chapter(last.surah).versesCount;
      return endsSurah && widths[line]! < _minLineWidthInEm * 0.85;
    }

    final justified = [
      for (final MapEntry(key: line, value: width) in widths.entries)
        if (!isShort(line)) width,
    ];
    final lineWidthInEm = justified
        .fold(_minLineWidthInEm, math.max)
        .clamp(_minLineWidthInEm, _maxLineWidthInEm);

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineHeight = constraints.maxHeight / _linesPerPage;
        // Width-bound on phones; on short/wide screens the text block narrows
        // so the glyphs keep their proportions.
        final fontSize = math.min(
          constraints.maxWidth / lineWidthInEm,
          lineHeight / _minLineHeightInEm,
        );
        final width = fontSize * lineWidthInEm;
        // Pages 1–2 have short lines; the print sets them larger.
        final glyphSize = page.isCentered ? fontSize * 1.15 : fontSize;
        final lines = [
          for (final line in page.lines)
            SizedBox(
              height: lineHeight,
              child: switch (line) {
                MushafWordsLine() => _WordsLine(
                    line: line,
                    centered: isShort(line),
                    fontSize: glyphSize,
                    width: width,
                    height: lineHeight,
                    selectedAyah: widget.selectedAyah,
                    onTap: (word) => widget.onAyahTap(word, page),
                  ),
                MushafSurahHeaderLine(:final surah) => _SurahFrame(
                    number: surah,
                    versesCount: _repo.chapter(surah).versesCount,
                    height: lineHeight,
                  ),
                MushafBismillahLine() => Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _repo.bismillahGlyphs,
                        textDirection: TextDirection.rtl,
                        style: _glyphStyle(
                          QcfFontManager.familyFor(1),
                          fontSize * 1.1,
                        ),
                      ),
                    ),
                  ),
              },
            ),
        ];
        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisAlignment: page.isCentered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: lines,
            ),
          ),
        );
      },
    );
  }
}

TextStyle _glyphStyle(String family, double fontSize) => TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      height: 1,
      color: mushafInkColor,
    );

TextStyle _wordStyle(MushafWord word, double fontSize) =>
    _glyphStyle(QcfFontManager.familyFor(word.font), fontSize).copyWith(
      color: word.isEnd ? mushafAyahMarkerColor : mushafInkColor,
    );

/// A word's glyphs in reading order. PUA glyphs are bidi-LTR, so a word of
/// several glyphs (a ۞/۩ marker or a split word) is forced right to left.
String _wordText(MushafWord word) => word.code.length > 1
    ? '${MushafLayoutRepository.rtlOverride}${word.code}'
        '${MushafLayoutRepository.popDirectionalFormatting}'
    : word.code;

double _naturalWidth(MushafWordsLine line, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(children: [
      for (final word in line.words)
        TextSpan(text: _wordText(word), style: _wordStyle(word, fontSize)),
    ]),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

class _WordsLine extends StatelessWidget {
  const _WordsLine({
    required this.line,
    required this.centered,
    required this.fontSize,
    required this.width,
    required this.height,
    required this.selectedAyah,
    required this.onTap,
  });

  final MushafWordsLine line;

  /// Lines that end a surah early (and pages 1–2) are centered in the
  /// printed Mushaf; every other line is justified to the full width.
  final bool centered;
  final double fontSize;
  final double width;
  final double height;
  final ValueNotifier<String?> selectedAyah;
  final ValueChanged<MushafWord> onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedAyah,
      builder: (context, selected, _) {
        final words = [
          for (final word in line.words)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(word),
              child: Container(
                alignment: Alignment.center,
                padding: centered
                    ? EdgeInsets.symmetric(horizontal: fontSize * 0.12)
                    : null,
                color: word.verseKey == selected ? _highlightColor : null,
                child: Text(_wordText(word), style: _wordStyle(word, fontSize)),
              ),
            ),
        ];
        final row = Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centered
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: words,
        );
        if (centered) {
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(height: height, child: row),
            ),
          );
        }
        // Justified to the width; a rare over-wide line is scaled down.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            height: height,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: width),
              child: IntrinsicWidth(child: row),
            ),
          ),
        );
      },
    );
  }
}

/// The surah title frame: arabesque knots at both ends, "ترتيبها" and
/// "آياتها" medallions, and the calligraphic surah name in a cartouche.
class _SurahFrame extends StatelessWidget {
  const _SurahFrame({
    required this.number,
    required this.versesCount,
    required this.height,
  });

  final int number;
  final int versesCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final h = height * 0.94;
    final geometry = _SurahFrameGeometry(h);
    return Center(
      child: SizedBox(
        height: h,
        child: CustomPaint(
          painter: _SurahFramePainter(geometry),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(width: geometry.knotWidth),
              _SurahMetaText(
                label: 'ترتيبها',
                value: number,
                size: geometry.medallionRadius * 2,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: h * 0.35,
                    vertical: h * 0.18,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      surahNameGlyph(number),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'SurahNameV4',
                        fontSize: 40,
                        color: mushafInkColor,
                      ),
                    ),
                  ),
                ),
              ),
              _SurahMetaText(
                label: 'آياتها',
                value: versesCount,
                size: geometry.medallionRadius * 2,
              ),
              SizedBox(width: geometry.knotWidth),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahFrameGeometry {
  const _SurahFrameGeometry(this.height);

  final double height;

  double get knotWidth => height * 1.55;
  double get medallionRadius => height * 0.36;
}

class _SurahMetaText extends StatelessWidget {
  const _SurahMetaText({
    required this.label,
    required this.value,
    required this.size,
  });

  final String label;
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: FittedBox(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label\n'),
              TextSpan(text: arabicDigits(value), style: _digitsStyle),
            ]),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 14,
              height: 1.1,
              color: mushafInkColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// UthmanicHafs draws digit runs as ayah-end rosettes, so numbers use a
/// plain Arabic face.
const TextStyle _digitsStyle = TextStyle(
  fontFamily: 'IBM Plex Sans Arabic',
  fontWeight: FontWeight.w500,
  color: mushafInkColor,
);

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.surahName, required this.juz});

  final String surahName;
  final int juz;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TopLabelBox(text: 'الجزء ${arabicJuzName(juz)}'),
        _TopLabelBox(text: 'سورة $surahName'),
      ],
    );
  }
}

class _TopLabelBox extends StatelessWidget {
  const _TopLabelBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 84.w, maxWidth: 130.w),
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        color: _frameLight,
        border: Border.all(color: _frameInk, width: 1),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
        decoration: BoxDecoration(
          border: Border.all(color: _frameRed, width: 0.8),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 12.sp,
            height: 1.3,
            color: mushafInkColor,
          ),
        ),
      ),
    );
  }
}

class _PageNumberMedallion extends StatelessWidget {
  const _PageNumberMedallion({required this.number, required this.height});

  final int number;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 2.6,
      height: height,
      child: CustomPaint(
        painter: const _MedallionPainter(),
        child: Center(
          child: Text(
            arabicDigits(number),
            textDirection: TextDirection.rtl,
            style: _digitsStyle.copyWith(fontSize: height * 0.48, height: 1),
          ),
        ),
      ),
    );
  }
}

Paint _fill(Color color) => Paint()..color = color;

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width;

/// A tulip pointing up from [Offset.zero], [size] tall.
Path _tulipPath(double size) {
  final s = size;
  return Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-s * 0.32, -s * 0.5, 0, -s)
    ..quadraticBezierTo(s * 0.32, -s * 0.5, 0, 0)
    ..moveTo(0, -s * 0.08)
    ..quadraticBezierTo(-s * 0.62, -s * 0.18, -s * 0.5, -s * 0.78)
    ..quadraticBezierTo(-s * 0.2, -s * 0.42, 0, -s * 0.08)
    ..moveTo(0, -s * 0.08)
    ..quadraticBezierTo(s * 0.62, -s * 0.18, s * 0.5, -s * 0.78)
    ..quadraticBezierTo(s * 0.2, -s * 0.42, 0, -s * 0.08);
}

/// A rosette of [petals] round petals around a red heart.
void _drawRosette(Canvas canvas, Offset c, double r, {int petals = 8}) {
  for (var i = 0; i < petals; i++) {
    final a = i * 2 * math.pi / petals;
    final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.62;
    canvas
      ..drawCircle(p, r * 0.34, _fill(_framePink))
      ..drawCircle(p, r * 0.34, _stroke(_frameRed, r * 0.08));
  }
  canvas
    ..drawCircle(c, r * 0.36, _fill(_frameRed))
    ..drawCircle(c, r * 0.36, _stroke(_frameInk, r * 0.06));
}

/// The printed page border: a band of red tulips between blue-grey rules,
/// rosettes in the corners and a double rule around the text.
class _MushafFramePainter extends CustomPainter {
  const _MushafFramePainter(this.band);

  final double band;

  @override
  void paint(Canvas canvas, Size size) {
    final b = band;
    final outer = (Offset.zero & size).deflate(0.8);
    final inner = outer.deflate(b);
    canvas
      ..drawRect(outer, _fill(_frameLight))
      ..drawRect(inner, _fill(_cream))
      ..drawRect(outer, _stroke(_frameInk, 1.6))
      ..drawRect(outer.deflate(2.2), _stroke(_frameRed, 0.8))
      ..drawRect(inner.inflate(2.2), _stroke(_frameRed, 0.8))
      ..drawRect(inner, _stroke(_frameInk, 1.4))
      ..drawRect(inner.deflate(2.6), _stroke(_frameRed, 1))
      ..drawRect(inner.deflate(4.4), _stroke(_frameInk, 0.7));

    final mid = b / 2;
    _side(canvas, Offset(outer.left + b, outer.top + mid), outer.width - 2 * b,
        0);
    _side(canvas, Offset(outer.right - b, outer.bottom - mid),
        outer.width - 2 * b, math.pi);
    _side(canvas, Offset(outer.right - mid, outer.top + b),
        outer.height - 2 * b, math.pi / 2);
    _side(canvas, Offset(outer.left + mid, outer.bottom - b),
        outer.height - 2 * b, -math.pi / 2);

    for (final corner in [
      outer.topLeft + Offset(mid, mid),
      outer.topRight + Offset(-mid, mid),
      outer.bottomLeft + Offset(mid, -mid),
      outer.bottomRight + Offset(-mid, -mid),
    ]) {
      final square = Rect.fromCenter(center: corner, width: b, height: b);
      canvas
        ..drawRect(square, _fill(_framePink))
        ..drawRect(square.deflate(1), _stroke(_frameInk, 1));
      _drawRosette(canvas, corner, b * 0.4);
    }
  }

  /// Tulips along a side of [length] starting at [start], running in
  /// direction [angle]; they alternate pointing out and in.
  void _side(Canvas canvas, Offset start, double length, double angle) {
    final b = band;
    final count = math.max(1, (length / (b * 1.3)).round());
    final step = length / count;
    canvas
      ..save()
      ..translate(start.dx, start.dy)
      ..rotate(angle);
    for (var i = 0; i < count; i++) {
      final x = step * (i + 0.5);
      final up = i.isEven;
      canvas
        ..save()
        ..translate(x, up ? b * 0.34 : -b * 0.34)
        ..rotate(up ? 0 : math.pi);
      final tulip = _tulipPath(b * 0.68);
      canvas
        ..drawPath(tulip, _fill(_frameRed))
        ..drawPath(tulip, _stroke(_frameInk, 0.7))
        ..restore();
      // Blue-grey leaves between the tulips.
      final leaf = Rect.fromCenter(
        center: Offset(step * (i + 1), 0),
        width: b * 0.22,
        height: b * 0.5,
      );
      if (i < count - 1) canvas.drawOval(leaf, _fill(_frameInk));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MushafFramePainter oldDelegate) =>
      oldDelegate.band != band;
}

class _SurahFramePainter extends CustomPainter {
  const _SurahFramePainter(this.geometry);

  final _SurahFrameGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final rect = (Offset.zero & size).deflate(0.8);
    canvas
      ..drawRect(rect, _fill(_framePink))
      ..drawRect(rect, _stroke(_frameInk, 1.5))
      ..drawRect(rect.deflate(h * 0.07), _stroke(_frameRed, 1))
      ..drawRect(rect.deflate(h * 0.11), _stroke(_frameInk, 0.6));

    final knot = geometry.knotWidth;
    _drawKnot(canvas, Offset(knot / 2 + h * 0.08, h / 2), h);
    _drawKnot(canvas, Offset(size.width - knot / 2 - h * 0.08, h / 2), h);

    // Cartouche with pointed ends between the two medallions.
    final r = geometry.medallionRadius;
    final left = knot + r * 2 - r * 0.3;
    final right = size.width - knot - r * 2 + r * 0.3;
    Path cartouche(double inset) {
      final l = left + inset * 1.6;
      final rt = right - inset * 1.6;
      final top = h * 0.16 + inset;
      final bottom = h * 0.84 - inset;
      final tip = h * 0.34;
      return Path()
        ..moveTo(l, h / 2)
        ..quadraticBezierTo(l + tip * 0.2, top, l + tip, top)
        ..lineTo(rt - tip, top)
        ..quadraticBezierTo(rt - tip * 0.2, top, rt, h / 2)
        ..quadraticBezierTo(rt - tip * 0.2, bottom, rt - tip, bottom)
        ..lineTo(l + tip, bottom)
        ..quadraticBezierTo(l + tip * 0.2, bottom, l, h / 2)
        ..close();
    }

    final outline = cartouche(0);
    canvas
      ..drawPath(outline, _fill(_cream))
      ..drawPath(outline, _stroke(_frameInk, 1.2))
      ..drawPath(cartouche(h * 0.05), _stroke(_frameRed, 0.7));

    _drawMedallion(canvas, Offset(size.width - knot - r, h / 2), r);
    _drawMedallion(canvas, Offset(knot + r, h / 2), r);
  }

  /// Interlaced loops around a rosette, inside a rounded panel.
  static void _drawKnot(Canvas canvas, Offset c, double h) {
    final panel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: h * 1.3, height: h * 0.72),
      Radius.circular(h * 0.36),
    );
    canvas
      ..drawRRect(panel, _fill(_frameLight))
      ..drawRRect(panel, _stroke(_frameInk, 0.9));
    final loop = _stroke(_frameRed, h * 0.045);
    for (final dx in [-1.0, 1.0]) {
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: c.translate(dx * h * 0.3, 0),
            width: h * 0.52,
            height: h * 0.52,
          ),
          loop,
        )
        ..drawOval(
          Rect.fromCenter(
            center: c.translate(dx * h * 0.18, 0),
            width: h * 0.42,
            height: h * 0.62,
          ),
          loop,
        );
    }
    _drawRosette(canvas, c, h * 0.2);
  }

  /// A scalloped round medallion holding "ترتيبها" / "آياتها".
  static void _drawMedallion(Canvas canvas, Offset c, double r) {
    const scallops = 12;
    for (var i = 0; i < scallops; i++) {
      final a = i * 2 * math.pi / scallops;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.9;
      canvas
        ..drawCircle(p, r * 0.2, _fill(_frameRed))
        ..drawCircle(p, r * 0.2, _stroke(_frameInk, 0.5));
    }
    canvas
      ..drawCircle(c, r * 0.9, _fill(_cream))
      ..drawCircle(c, r * 0.9, _stroke(_frameInk, 1))
      ..drawCircle(c, r * 0.8, _stroke(_frameRed, 0.6));
  }

  @override
  bool shouldRepaint(covariant _SurahFramePainter oldDelegate) =>
      oldDelegate.geometry.height != geometry.height;
}

/// The page-number cartouche sitting on the bottom border.
class _MedallionPainter extends CustomPainter {
  const _MedallionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final c = Offset(w / 2, h / 2);
    // Pointed ends.
    final tips = Path()
      ..moveTo(0, h / 2)
      ..lineTo(w * 0.2, h * 0.22)
      ..lineTo(w * 0.8, h * 0.22)
      ..lineTo(w, h / 2)
      ..lineTo(w * 0.8, h * 0.78)
      ..lineTo(w * 0.2, h * 0.78)
      ..close();
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: w * 0.66, height: h * 0.92),
      Radius.circular(h * 0.46),
    );
    canvas
      ..drawPath(tips, _fill(_framePink))
      ..drawPath(tips, _stroke(_frameInk, 1))
      ..drawRRect(body, _fill(_cream))
      ..drawRRect(body, _stroke(_frameInk, 1.3))
      ..drawRRect(body.deflate(h * 0.08), _stroke(_frameRed, 0.8));
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) => false;
}

class _FontError extends StatelessWidget {
  const _FontError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.greyColor, size: 40),
          SizedBox(height: 10.h),
          Text(
            'تعذر تحميل خط الصفحة، تحقق من الاتصال بالإنترنت',
            textAlign: TextAlign.center,
            style: TextStyles.greyRegular15,
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'إعادة المحاولة',
              style: TextStyles.blackBold14
                  .copyWith(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
