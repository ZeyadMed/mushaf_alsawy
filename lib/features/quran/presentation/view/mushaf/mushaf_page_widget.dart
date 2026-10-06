import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/helpers/arabic_digits.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/mushaf_layout_model.dart';
import 'package:mushaf_alsawy/features/quran/data/mushaf_layout_repository.dart';
import 'package:mushaf_alsawy/features/quran/data/qcf_font_manager.dart';

const Color mushafInkColor = Color(0xff1b1b1b);
const Color mushafFrameColor = Color(0xff6b7a2e);
const Color mushafAyahMarkerColor = Color(0xff6b7a2e);
const Color _highlightColor = Color(0x336b7a2e);

// QCF fonts ship one weight; w600+ makes the engine synthesize a bolder stroke.
const FontWeight mushafTextWeight = FontWeight.w600;

// Olive-green frame colours.
const Color _frameInk = Color(0xff3f4a1c);
const Color _frameAccent = Color(0xff6b7a2e);
const Color _frameTint = Color(0xffdde3c0);
const Color _frameLight = Color(0xfff7f8ec);
const Color _cream = Color.fromARGB(255, 255, 255, 255);

/// QPC v4 glyphs keep their natural width (the print justifies with spacing),
/// so each page is sized to its widest justified line, within these bounds;
/// a line wider than the upper bound is scaled down on its own.
const double _minLineWidthInEm = 15.5;
const double _maxLineWidthInEm = 19;
const double _minLineHeightInEm = 1.45;
const int _linesPerPage = 15;

/// Space on either side of each word of a centered line, in em.
const double _centeredWordPaddingInEm = 0.12;

/// Natural widths of a words line in em: its glyphs alone, and with one
/// space between words (see [_lineSpan]).
typedef _LineWidths = ({double glyphs, double spaced});

/// Line widths of every page measured so far. Pages are measured once per
/// run, not on every build of their (short-lived) widget.
final Map<int, Map<MushafWordsLine, _LineWidths>> _lineWidthsCache = {};

/// Measures [page]'s lines; its fonts must be loaded.
Map<MushafWordsLine, _LineWidths> _measurePage(MushafPage page) =>
    _lineWidthsCache[page.number] ??= {
      for (final line in page.lines.whereType<MushafWordsLine>())
        line: _measureLine(line.words),
    };

/// Lays the line out once at font size 100; its glyphs alone are as wide
/// as the whole less its spaces.
_LineWidths _measureLine(List<MushafWord> words) {
  final painter = TextPainter(
    text: _lineSpan(words, 100),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  var spaces = 0.0;
  var start = 1; // After the right-to-left override.
  for (final word in words.take(words.length - 1)) {
    start += word.code.length;
    for (final box in painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + 1),
    )) {
      spaces += box.right - box.left;
    }
    start += 1;
  }
  final spaced = painter.width;
  painter.dispose();
  return (glyphs: (spaced - spaces) / 100, spaced: spaced / 100);
}

/// Measures [page] ahead of its first build, if its fonts are loaded, so
/// that building it during a swipe skips the measuring.
void precacheMushafPage(MushafPage page) {
  final fonts = getIt<QcfFontManager>();
  if (getIt<MushafLayoutRepository>()
      .fontsOf(page.number)
      .every(fonts.isLoaded)) {
    _measurePage(page);
  }
}

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

  Set<int> get _pageFonts => _repo.fontsOf(widget.page.number);

  @override
  void initState() {
    super.initState();
    _fontsReady = _loadFonts();
  }

  // Bismillah lines use font 1, which is bundled.
  Future<void> _loadFonts() {
    final ready = Future.wait(_pageFonts.map(_fonts.ensureFont));
    // Lets the page turn into an image once its text is set.
    ready.then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
    return ready;
  }

  bool get _fontsLoaded => _pageFonts.every(_fonts.isLoaded);

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final chapter = _repo.chapter(page.firstSurah);
    final band = 13.w;
    return _PageRaster(
      enabled: _fontsLoaded,
      child: Padding(
        padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
        child: Column(
          children: [
            _PageHeader(surahName: chapter.name, juz: page.juz),
            SizedBox(height: 3.h),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _MushafFrame(band: band)),
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
      ),
    );
  }

  Widget _buildLines() {
    final page = widget.page;
    final widths = _measurePage(page);
    bool isShort(MushafWordsLine line) {
      if (page.isCentered) return true;
      final last = line.words.last;
      final endsSurah =
          last.isEnd && last.ayah == _repo.chapter(last.surah).versesCount;
      return endsSurah && widths[line]!.glyphs < _minLineWidthInEm * 0.85;
    }

    final justified = [
      for (final MapEntry(key: line, value: width) in widths.entries)
        if (!isShort(line)) width.glyphs,
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
                    widths: widths[line]!,
                    centered: isShort(line),
                    fontSize: glyphSize,
                    width: width,
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
      fontWeight: mushafTextWeight,
      height: 1,
      color: mushafInkColor,
    );

TextStyle _wordStyle(MushafWord word, double fontSize) =>
    _glyphStyle(QcfFontManager.familyFor(word.font), fontSize).copyWith(
      color: word.isEnd ? mushafAyahMarkerColor : mushafInkColor,
    );

/// A words line as one paragraph: the words in reading order with a space,
/// widened by [wordSpacing], between them. PUA glyphs are bidi-LTR, so the
/// whole line is forced right to left; in the text, each word starts after
/// the override and after the word and space before it.
TextSpan _lineSpan(
  List<MushafWord> words,
  double fontSize, {
  double wordSpacing = 0,
  TextLeadingDistribution? leadingDistribution,
}) {
  return TextSpan(
    text: MushafLayoutRepository.rtlOverride,
    style: _wordStyle(words.first, fontSize)
        .copyWith(leadingDistribution: leadingDistribution),
    children: [
      for (final (i, word) in words.indexed) ...[
        if (i > 0)
          // Widened by letter spacing on the space alone: the engine applies
          // word spacing by the text after a space, and drops it where the
          // font changes.
          TextSpan(
            text: ' ',
            style: _glyphStyle(
              QcfFontManager.familyFor(words[i - 1].font),
              fontSize,
            ).copyWith(letterSpacing: wordSpacing),
          ),
        TextSpan(text: word.code, style: _wordStyle(word, fontSize)),
      ],
      const TextSpan(text: MushafLayoutRepository.popDirectionalFormatting),
    ],
  );
}

/// A line of words, set as a single paragraph: far cheaper to build, lay out
/// and draw while swiping than a widget per word.
class _WordsLine extends StatelessWidget {
  const _WordsLine({
    required this.line,
    required this.widths,
    required this.centered,
    required this.fontSize,
    required this.width,
    required this.selectedAyah,
    required this.onTap,
  });

  final MushafWordsLine line;
  final _LineWidths widths;

  /// Lines that end a surah early (and pages 1–2) are centered in the
  /// printed Mushaf; every other line is justified to the full width.
  final bool centered;
  final double fontSize;
  final double width;
  final ValueListenable<String?> selectedAyah;
  final ValueChanged<MushafWord> onTap;

  @override
  Widget build(BuildContext context) {
    final gaps = line.words.length - 1;
    final double size;
    final double wordSpacing;
    if (centered) {
      // Words are padded on either side, so they are set twice the padding
      // apart; a line too wide for that is set smaller.
      const gap = 2 * _centeredWordPaddingInEm;
      size = math.min(fontSize, width / (widths.glyphs + gap * (gaps + 1)));
      final space = gaps == 0 ? 0.0 : (widths.spaced - widths.glyphs) / gaps;
      wordSpacing = size * (gap - space);
    } else {
      // Justified to the width; a rare over-wide line is set smaller.
      size = math.min(fontSize, width / widths.glyphs);
      wordSpacing = gaps == 0 ? 0 : (width - widths.spaced * size) / gaps;
    }
    return _LineText(
      words: line.words,
      fontSize: size,
      wordSpacing: wordSpacing,
      // A Text word inherited it from the theme; it places the glyphs in
      // the line.
      leadingDistribution:
          DefaultTextStyle.of(context).style.leadingDistribution,
      centered: centered,
      wordPadding: centered ? size * _centeredWordPaddingInEm : 0,
      selectedAyah: selectedAyah,
      onTap: onTap,
    );
  }
}

class _LineText extends LeafRenderObjectWidget {
  const _LineText({
    required this.words,
    required this.fontSize,
    required this.wordSpacing,
    required this.leadingDistribution,
    required this.centered,
    required this.wordPadding,
    required this.selectedAyah,
    required this.onTap,
  });

  final List<MushafWord> words;
  final double fontSize;
  final double wordSpacing;
  final TextLeadingDistribution? leadingDistribution;
  final bool centered;

  /// Width added on either side of a word to its highlight and tap area.
  final double wordPadding;
  final ValueListenable<String?> selectedAyah;
  final ValueChanged<MushafWord> onTap;

  @override
  _RenderLineText createRenderObject(BuildContext context) => _RenderLineText(
        words: words,
        fontSize: fontSize,
        wordSpacing: wordSpacing,
        leadingDistribution: leadingDistribution,
        centered: centered,
        wordPadding: wordPadding,
        selectedAyah: selectedAyah,
        onTap: onTap,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderLineText renderObject) {
    renderObject
      ..words = words
      ..fontSize = fontSize
      ..wordSpacing = wordSpacing
      ..leadingDistribution = leadingDistribution
      ..centered = centered
      ..wordPadding = wordPadding
      ..selectedAyah = selectedAyah
      ..onTap = onTap;
  }
}

/// Fills the line box with the line's paragraph, centered vertically as each
/// word was in its own box. The selected ayah is highlighted over the full
/// line height, and a tap is mapped back to the word under it.
class _RenderLineText extends RenderBox {
  _RenderLineText({
    required List<MushafWord> words,
    required double fontSize,
    required double wordSpacing,
    required TextLeadingDistribution? leadingDistribution,
    required bool centered,
    required double wordPadding,
    required ValueListenable<String?> selectedAyah,
    required this.onTap,
  })  : _words = words,
        _fontSize = fontSize,
        _wordSpacing = wordSpacing,
        _leadingDistribution = leadingDistribution,
        _centered = centered,
        _wordPadding = wordPadding,
        _selectedAyah = selectedAyah {
    _tap = TapGestureRecognizer()..onTapUp = _handleTapUp;
  }

  final TextPainter _painter =
      TextPainter(textDirection: TextDirection.rtl, maxLines: 1);
  late final TapGestureRecognizer _tap;
  ValueChanged<MushafWord> onTap;
  Offset _textOffset = Offset.zero;
  String? _selected;

  /// Horizontal extent of each word in the paragraph, found on first need.
  List<(double, double)>? _extents;

  List<MushafWord> _words;
  set words(List<MushafWord> value) {
    if (identical(value, _words)) return;
    _words = value;
    _markTextNeedsLayout();
  }

  double _fontSize;
  set fontSize(double value) {
    if (value == _fontSize) return;
    _fontSize = value;
    _markTextNeedsLayout();
  }

  double _wordSpacing;
  set wordSpacing(double value) {
    if (value == _wordSpacing) return;
    _wordSpacing = value;
    _markTextNeedsLayout();
  }

  TextLeadingDistribution? _leadingDistribution;
  set leadingDistribution(TextLeadingDistribution? value) {
    if (value == _leadingDistribution) return;
    _leadingDistribution = value;
    _markTextNeedsLayout();
  }

  bool _centered;
  set centered(bool value) {
    if (value == _centered) return;
    _centered = value;
    markNeedsLayout();
  }

  double _wordPadding;
  set wordPadding(double value) {
    if (value == _wordPadding) return;
    _wordPadding = value;
    markNeedsPaint();
  }

  ValueListenable<String?> _selectedAyah;
  set selectedAyah(ValueListenable<String?> value) {
    if (identical(value, _selectedAyah)) return;
    if (attached) _selectedAyah.removeListener(_selectionChanged);
    _selectedAyah = value;
    if (attached) {
      value.addListener(_selectionChanged);
      _selectionChanged();
    }
  }

  void _markTextNeedsLayout() {
    _painter.text = null;
    _extents = null;
    markNeedsLayout();
  }

  /// Repaints only the lines holding the newly or previously selected ayah.
  void _selectionChanged() {
    final previous = _selected;
    _selected = _selectedAyah.value;
    if (_words.any((w) => w.verseKey == previous || w.verseKey == _selected)) {
      markNeedsPaint();
    }
  }

  List<(double, double)> _computeExtents() {
    final extents = <(double, double)>[];
    var start = 1; // After the right-to-left override.
    for (final word in _words) {
      final end = start + word.code.length;
      final boxes = _painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      extents.add((
        boxes.fold(double.infinity, (left, box) => math.min(left, box.left)),
        boxes.fold(
            -double.infinity, (right, box) => math.max(right, box.right)),
      ));
      start = end + 1; // After the space.
    }
    return extents;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _selected = _selectedAyah.value;
    _selectedAyah.addListener(_selectionChanged);
  }

  @override
  void detach() {
    _selectedAyah.removeListener(_selectionChanged);
    super.detach();
  }

  @override
  void dispose() {
    _tap.dispose();
    _painter.dispose();
    super.dispose();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    if (_painter.text == null) {
      _painter
        ..text = _lineSpan(
          _words,
          _fontSize,
          wordSpacing: _wordSpacing,
          leadingDistribution: _leadingDistribution,
        )
        // A space may come from a fallback font; the line keeps the metrics
        // of the Mushaf font, as a word alone had.
        ..strutStyle = StrutStyle(
          fontFamily: QcfFontManager.familyFor(_words.first.font),
          fontSize: _fontSize,
          height: 1,
          leadingDistribution: _leadingDistribution,
          forceStrutHeight: true,
        );
    }
    _painter.layout();
    size = constraints.biggest;
    _textOffset = Offset(
      _centered
          ? (size.width - _painter.width) / 2
          // A justified line fills the width, or a one-word line starts on
          // the right.
          : size.width - _painter.width,
      (size.height - _painter.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final origin = offset + _textOffset;
    if (_selected case final selected?) {
      final extents = _extents ??= _computeExtents();
      final highlight = Paint()..color = _highlightColor;
      for (final (i, word) in _words.indexed) {
        final (left, right) = extents[i];
        if (word.verseKey != selected || left > right) continue;
        context.canvas.drawRect(
          Rect.fromLTRB(
            origin.dx + left - _wordPadding,
            offset.dy,
            origin.dx + right + _wordPadding,
            offset.dy + size.height,
          ),
          highlight,
        );
      }
    }
    _painter.paint(context.canvas, origin);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) _tap.addPointer(event);
  }

  void _handleTapUp(TapUpDetails details) {
    final x = details.localPosition.dx - _textOffset.dx;
    final extents = _extents ??= _computeExtents();
    for (final (i, (left, right)) in extents.indexed) {
      if (x >= left - _wordPadding && x <= right + _wordPadding) {
        onTap(_words[i]);
        return;
      }
    }
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
          border: Border.all(color: _frameAccent, width: 0.8),
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
      ..drawCircle(p, r * 0.34, _fill(_frameTint))
      ..drawCircle(p, r * 0.34, _stroke(_frameAccent, r * 0.08));
  }
  canvas
    ..drawCircle(c, r * 0.36, _fill(_frameAccent))
    ..drawCircle(c, r * 0.36, _stroke(_frameInk, r * 0.06));
}

/// Draws the page as an image of itself. Drawing the text is what makes a
/// swipe slow: every QPC word is a glyph of its own, so a page brings ~140
/// large glyphs for the GPU to render, and Impeller renders them again on
/// every frame the page moves. An image of the page costs next to nothing to
/// move.
///
/// A page gets its image the first time it is painted. The pages beside the
/// current one, which the page view lays out without painting, get theirs
/// ahead, right after a swipe ends, so the next swipe only moves images. Any
/// change below (an ayah highlighted) drops the image; the page stays laid
/// out underneath, so taps still reach its words.
class _PageRaster extends SingleChildRenderObjectWidget {
  const _PageRaster({required this.enabled, required super.child});

  /// False while the page is still changing (its fonts loading).
  final bool enabled;

  @override
  _RenderPageRaster createRenderObject(BuildContext context) =>
      _RenderPageRaster(
        enabled: enabled,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        scrolling: Scrollable.maybeOf(context)?.position.isScrollingNotifier,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderPageRaster renderObject) {
    renderObject
      ..enabled = enabled
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..scrolling = Scrollable.maybeOf(context)?.position.isScrollingNotifier;
  }
}

class _RenderPageRaster extends RenderProxyBox {
  _RenderPageRaster({
    required bool enabled,
    required double devicePixelRatio,
    required ValueListenable<bool>? scrolling,
  })  : _enabled = enabled,
        _devicePixelRatio = devicePixelRatio,
        _scrolling = scrolling;

  ui.Image? _raster;

  /// Bumped whenever the page changes, so a late image of an older look is
  /// thrown away.
  int _version = 0;

  /// The version being rendered ahead, if any.
  int? _aheadVersion;
  bool _showingRaster = false;

  /// The scroll position this is waiting on to settle, if any.
  ValueListenable<bool>? _awaitedScrolling;

  bool _enabled;
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  ValueListenable<bool>? _scrolling;
  set scrolling(ValueListenable<bool>? value) {
    if (identical(value, _scrolling)) return;
    _stopAwaitingScroll();
    _scrolling = value;
    _renderAhead();
  }

  /// Reached from below too, and after every layout: whatever changed makes
  /// the image stale.
  @override
  void markNeedsPaint() {
    if (!_showingRaster) {
      _dropRaster();
      _version++;
      _renderAhead();
    }
    super.markNeedsPaint();
  }

  @override
  void detach() {
    _stopAwaitingScroll();
    _dropRaster();
    _aheadVersion = null;
    super.detach();
  }

  @override
  void dispose() {
    _dropRaster();
    super.dispose();
  }

  void _dropRaster() {
    _raster?.dispose();
    _raster = null;
  }

  void _showRaster(ui.Image image) {
    _raster = image;
    _showingRaster = true;
    markNeedsPaint();
    _showingRaster = false;
  }

  void _stopAwaitingScroll() {
    _awaitedScrolling?.removeListener(_scrollingChanged);
    _awaitedScrolling = null;
  }

  void _scrollingChanged() {
    if (_awaitedScrolling?.value ?? true) return;
    _stopAwaitingScroll();
    _renderAhead();
  }

  /// Renders the image before the page is painted, once nothing scrolls.
  void _renderAhead() {
    if (_raster != null || !_enabled || !attached) return;
    if (_aheadVersion == _version) return;
    if (_scrolling case final scrolling? when scrolling.value) {
      // Its GPU work would compete with the swipe's frames; wait for the end.
      _awaitedScrolling ??= scrolling..addListener(_scrollingChanged);
      return;
    }
    final version = _aheadVersion = _version;
    // After a frame the tree is laid out and clean, so the page can be
    // painted again into an image of its own.
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _renderAheadNow(version))
      ..ensureVisualUpdate();
  }

  void _renderAheadNow(int version) {
    if (_aheadVersion != version) return;
    if (version != _version || _raster != null || !_canRender) {
      _aheadVersion = null;
      return;
    }
    if (_scrolling?.value ?? false) {
      _aheadVersion = null;
      return _renderAhead();
    }
    final layer = _paintChildToLayer();
    // Unlike toImageSync, which leaves the GPU work for the first draw (the
    // next swipe), this renders the image now.
    layer.toImage(Offset.zero & size, pixelRatio: _devicePixelRatio).then(
      (image) {
        layer.dispose();
        if (_aheadVersion == version) _aheadVersion = null;
        if (version != _version || _raster != null || !attached) {
          image.dispose();
        } else {
          _showRaster(image);
        }
      },
      onError: (Object _) {
        layer.dispose();
        if (_aheadVersion == version) _aheadVersion = null;
      },
    );
  }

  bool get _canRender =>
      _enabled && attached && child != null && hasSize && !size.isEmpty;

  OffsetLayer _paintChildToLayer() {
    final layer = OffsetLayer();
    // ignore: invalid_use_of_protected_member
    final context = PaintingContext(layer, Offset.zero & size);
    context.paintChild(child!, Offset.zero);
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    return layer;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_canRender) return super.paint(context, offset);
    // Not rendered ahead (a quick second swipe): render it now, so of this
    // swipe only the first frame draws the text.
    final raster = _raster ??= () {
      final layer = _paintChildToLayer();
      final image = layer.toImageSync(
        Offset.zero & size,
        pixelRatio: _devicePixelRatio,
      );
      layer.dispose();
      return image;
    }();
    context.canvas.drawImageRect(
      raster,
      Offset.zero & Size(raster.width.toDouble(), raster.height.toDouble()),
      offset &
          Size(
            raster.width / _devicePixelRatio,
            raster.height / _devicePixelRatio,
          ),
      Paint()..filterQuality = FilterQuality.low,
    );
  }
}

/// The page border, drawn once into an image that every page shares: it is
/// the same on all of them, and Impeller would otherwise redraw its few
/// hundred paths on every frame of a swipe.
class _MushafFrame extends StatelessWidget {
  const _MushafFrame({required this.band});

  final double band;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _FrameImagePainter(
          band,
          MediaQuery.devicePixelRatioOf(context),
        ),
      );
}

class _FrameImagePainter extends CustomPainter {
  const _FrameImagePainter(this.band, this.pixelRatio);

  final double band;
  final double pixelRatio;

  static ui.Image? _image;
  static (Size, double, double)? _imageKey;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final key = (size, band, pixelRatio);
    var image = _image;
    if (image == null || _imageKey != key) {
      final recorder = ui.PictureRecorder();
      _MushafFramePainter(band)
          .paint(Canvas(recorder)..scale(pixelRatio), size);
      final picture = recorder.endRecording();
      image = picture.toImageSync(
        (size.width * pixelRatio).ceil(),
        (size.height * pixelRatio).ceil(),
      );
      picture.dispose();
      _image?.dispose();
      _image = image;
      _imageKey = key;
    }
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & Size(image.width / pixelRatio, image.height / pixelRatio),
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameImagePainter oldDelegate) =>
      oldDelegate.band != band || oldDelegate.pixelRatio != pixelRatio;
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
      ..drawRect(outer.deflate(2.2), _stroke(_frameAccent, 0.8))
      ..drawRect(inner.inflate(2.2), _stroke(_frameAccent, 0.8))
      ..drawRect(inner, _stroke(_frameInk, 1.4))
      ..drawRect(inner.deflate(2.6), _stroke(_frameAccent, 1))
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
        ..drawRect(square, _fill(_frameTint))
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
        ..drawPath(tulip, _fill(_frameAccent))
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
      ..drawRect(rect, _fill(_frameTint))
      ..drawRect(rect, _stroke(_frameInk, 1.5))
      ..drawRect(rect.deflate(h * 0.07), _stroke(_frameAccent, 1))
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
      ..drawPath(cartouche(h * 0.05), _stroke(_frameAccent, 0.7));

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
    final loop = _stroke(_frameAccent, h * 0.045);
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
        ..drawCircle(p, r * 0.2, _fill(_frameAccent))
        ..drawCircle(p, r * 0.2, _stroke(_frameInk, 0.5));
    }
    canvas
      ..drawCircle(c, r * 0.9, _fill(_cream))
      ..drawCircle(c, r * 0.9, _stroke(_frameInk, 1))
      ..drawCircle(c, r * 0.8, _stroke(_frameAccent, 0.6));
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
      ..drawPath(tips, _fill(_frameTint))
      ..drawPath(tips, _stroke(_frameInk, 1))
      ..drawRRect(body, _fill(_cream))
      ..drawRRect(body, _stroke(_frameInk, 1.3))
      ..drawRRect(body.deflate(h * 0.08), _stroke(_frameAccent, 0.8));
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
