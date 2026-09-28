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
const Color _highlightColor = Color(0x33c9a24a);

/// Full-width lines in the QCF V1 fonts are at most ~15.1em wide, so this
/// ratio fills the width on every page while keeping one font size.
const double _lineWidthInEm = 15.4;
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

/// One page of the Madina Mushaf: 15 lines in the page's own QCF font.
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
  late Future<void> _fontsReady;

  bool get _needsBismillahFont =>
      widget.page.lines.any((line) => line is MushafBismillahLine);

  @override
  void initState() {
    super.initState();
    _fontsReady = _loadFonts();
  }

  Future<void> _loadFonts() => Future.wait([
        _fonts.ensurePageFont(widget.page.number),
        if (_needsBismillahFont) _fonts.ensurePageFont(1),
      ]);

  bool get _fontsLoaded =>
      _fonts.isLoaded(widget.page.number) &&
      (!_needsBismillahFont || _fonts.isLoaded(1));

  @override
  Widget build(BuildContext context) {
    final repo = getIt<MushafLayoutRepository>();
    final page = widget.page;
    final chapter = repo.chapter(page.firstSurah);
    return Padding(
      padding: EdgeInsets.zero,
      child: CustomPaint(
        painter: const _MushafBorderPainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 5.h),
          child: Column(
            children: [
              _PageHeader(
                surahNumber: chapter.number,
                surahName: chapter.name,
                versesCount: chapter.versesCount,
                juz: page.juz,
              ),
              SizedBox(height: 6.h),
              Expanded(
                child: FutureBuilder<void>(
                  future: _fontsReady,
                  builder: (context, snapshot) {
                    if (_fontsLoaded) return _buildLines(repo);
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
              SizedBox(height: 4.h),
              Text(
                arabicDigits(page.number),
                style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLines(MushafLayoutRepository repo) {
    final page = widget.page;
    final family = QcfFontManager.familyFor(page.number);
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineHeight = constraints.maxHeight / _linesPerPage;
        // Width-bound on phones; on short/wide screens the text block narrows
        // so the glyphs keep their proportions.
        final fontSize = math.min(
          constraints.maxWidth / _lineWidthInEm,
          lineHeight / _minLineHeightInEm,
        );
        final width = fontSize * _lineWidthInEm;
        // Pages 1–2 have short lines; the print sets them larger.
        final glyphSize = page.isCentered ? fontSize * 1.25 : fontSize;
        final lines = [
          for (final line in page.lines)
            SizedBox(
              height: lineHeight,
              child: switch (line) {
                MushafWordsLine() => _WordsLine(
                    line: line,
                    page: page,
                    family: family,
                    fontSize: glyphSize,
                    width: width,
                    height: lineHeight,
                    selectedAyah: widget.selectedAyah,
                    onTap: (word) => widget.onAyahTap(word, page),
                  ),
                MushafSurahHeaderLine(:final surah) => _SurahFrame(
                    number: surah,
                    name: repo.chapter(surah).name,
                    versesCount: repo.chapter(surah).versesCount,
                    height: lineHeight,
                    fontSize: fontSize,
                  ),
                MushafBismillahLine() => Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        repo.bismillahGlyphs,
                        textDirection: TextDirection.rtl,
                        style: _glyphStyle(
                          QcfFontManager.familyFor(1),
                          fontSize * 1.5,
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

class _WordsLine extends StatelessWidget {
  const _WordsLine({
    required this.line,
    required this.page,
    required this.family,
    required this.fontSize,
    required this.width,
    required this.height,
    required this.selectedAyah,
    required this.onTap,
  });

  final MushafWordsLine line;
  final MushafPage page;
  final String family;
  final double fontSize;
  final double width;
  final double height;
  final ValueNotifier<String?> selectedAyah;
  final ValueChanged<MushafWord> onTap;

  /// Lines that end a surah early (and pages 1–2) are centered in the
  /// printed Mushaf; every other line is justified to the full width.
  bool _isShortLine(TextStyle style) {
    if (page.isCentered) return true;
    final last = line.words.last;
    final endsSurah = last.isEnd &&
        last.ayah ==
            getIt<MushafLayoutRepository>().chapter(last.surah).versesCount;
    if (!endsSurah) return false;
    final painter = TextPainter(
      text: TextSpan(text: line.words.map((w) => w.code).join(), style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    final natural = painter.width;
    painter.dispose();
    return natural < width * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final style = _glyphStyle(family, fontSize);
    final centered = _isShortLine(style);
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
                child: Text(word.code, style: style),
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
        if (centered) return Center(child: row);
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

class _SurahFrame extends StatelessWidget {
  const _SurahFrame({
    required this.number,
    required this.name,
    required this.versesCount,
    required this.height,
    required this.fontSize,
  });

  final int number;
  final String name;
  final int versesCount;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.03),
      child: CustomPaint(
        painter: _SurahHeaderPainter(height: height),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.15,
            vertical: height * 0.06,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _SurahMetaBox(
                text: 'ترتيبها\n${arabicDigits(number)}',
                width: fontSize * 3,
              ),
              Expanded(
                child: Text(
                  'سُورَةُ $name',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: fontSize * 0.82,
                    height: 1,
                    color: mushafInkColor,
                  ),
                ),
              ),
              _SurahMetaBox(
                text: 'آياتها\n${arabicDigits(versesCount)}',
                width: fontSize * 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahMetaBox extends StatelessWidget {
  const _SurahMetaBox({required this.text, required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 15,
          height: 1.05,
          color: mushafInkColor,
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.surahNumber,
    required this.surahName,
    required this.versesCount,
    required this.juz,
  });

  final int surahNumber;
  final String surahName;
  final int versesCount;
  final int juz;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TopLabelBox(
          text: 'الجزء ${arabicJuzName(juz)}',
          width: 108.w,
        ),
        _TopLabelBox(
          text: 'سورة $surahName',
          width: 108.w,
        ),
      ],
    );
  }
}

class _TopLabelBox extends StatelessWidget {
  const _TopLabelBox({required this.text, required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xfff1e4d4),
        border: Border.all(color: const Color(0xff394b55), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55394b55),
            offset: Offset(1, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyles.greyRegular15.copyWith(
          fontFamily: 'UthmanicHafs',
          fontSize: 11.sp,
          height: 1.05,
          color: mushafInkColor,
        ),
      ),
    );
  }
}

class _MushafBorderPainter extends CustomPainter {
  const _MushafBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    _stroke(canvas, outerRect.deflate(2), const Color(0xff53626a), 7);
    _stroke(canvas, outerRect.deflate(7), const Color(0xffc97678), 2);
    _stroke(canvas, outerRect.deflate(10), const Color(0xff394b55), 2);
    _stroke(canvas, outerRect.deflate(14), const Color(0xffc97678), 1);

    const step = 30.0;
    for (var x = 15.0; x < size.width - 12; x += step) {
      _drawFloralMotif(canvas, Offset(x, 6));
      _drawFloralMotif(canvas, Offset(x, size.height - 6));
    }
    for (var y = 28.0; y < size.height - 20; y += step) {
      _drawFloralMotif(canvas, Offset(6, y));
      _drawFloralMotif(canvas, Offset(size.width - 6, y));
    }
  }

  static void _stroke(Canvas canvas, Rect rect, Color color, double width) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  static void _drawFloralMotif(Canvas canvas, Offset center) {
    final outline = Paint()
      ..color = const Color(0xff394b55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final petal = Paint()..color = const Color(0xffc97678);
    canvas.drawCircle(center, 7, outline);
    canvas.drawCircle(center, 3, petal);
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * 5,
          center.dy + math.sin(angle) * 5,
        ),
        2.3,
        petal,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MushafBorderPainter oldDelegate) => false;
}

class _SurahHeaderPainter extends CustomPainter {
  const _SurahHeaderPainter({required this.height});

  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xfff1e4d4));
    _stroke(canvas, rect.deflate(1), const Color(0xff394b55), 2);
    _stroke(canvas, rect.deflate(4), const Color(0xffb76f68), 3);
    _stroke(canvas, rect.deflate(8), const Color(0xff394b55), 1);
    _drawSideOrnament(canvas, Offset(12, size.height / 2));
    _drawSideOrnament(canvas, Offset(size.width - 12, size.height / 2));
  }

  static void _stroke(Canvas canvas, Rect rect, Color color, double width) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  static void _drawSideOrnament(Canvas canvas, Offset center) {
    final outline = Paint()
      ..color = const Color(0xff394b55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final petal = Paint()..color = const Color(0xffc97678);
    canvas.drawCircle(center, 9, outline);
    canvas.drawCircle(center, 4, petal);
    canvas.drawCircle(center.translate(0, -7), 2.5, petal);
    canvas.drawCircle(center.translate(0, 7), 2.5, petal);
  }

  @override
  bool shouldRepaint(covariant _SurahHeaderPainter oldDelegate) =>
      oldDelegate.height != height;
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
