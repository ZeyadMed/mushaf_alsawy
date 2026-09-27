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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          _PageHeader(
            surahName: repo.chapter(page.firstSurah).name,
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
                    onRetry: () => setState(() => _fontsReady = _loadFonts()),
                  );
                }
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor),
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
                    name: repo.chapter(surah).name,
                    height: lineHeight,
                    fontSize: fontSize,
                  ),
                MushafBismillahLine() => Center(
                    child: Text(
                      repo.bismillahGlyphs,
                      textDirection: TextDirection.rtl,
                      style: _glyphStyle(QcfFontManager.familyFor(1), glyphSize),
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
    required this.name,
    required this.height,
    required this.fontSize,
  });

  final String name;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.08),
      decoration: BoxDecoration(
        color: const Color(0xffece2c3),
        borderRadius: BorderRadius.circular(height * 0.45),
        border: Border.all(color: mushafFrameColor, width: 1.4),
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.4),
          border: Border.all(color: mushafFrameColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Ornament(size: fontSize * 0.35),
            SizedBox(width: fontSize * 0.8),
            Text(
              'سُورَةُ $name',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: fontSize * 0.95,
                height: 1.2,
                color: mushafInkColor,
              ),
            ),
            SizedBox(width: fontSize * 0.8),
            _Ornament(size: fontSize * 0.35),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.surahName, required this.juz});

  final String surahName;
  final int juz;

  @override
  Widget build(BuildContext context) {
    final style = TextStyles.greyRegular15.copyWith(fontSize: 12.sp);
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('سورة $surahName', style: style),
        Text('الجزء ${arabicDigits(juz)}', style: style),
      ],
    );
  }
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

class _Ornament extends StatelessWidget {
  const _Ornament({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: mushafFrameColor.withValues(alpha: 0.25),
          border: Border.all(color: mushafFrameColor),
        ),
      ),
    );
  }
}
