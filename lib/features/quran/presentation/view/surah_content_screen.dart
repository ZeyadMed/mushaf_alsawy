import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/ayah_model.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_model.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view_model/cubit/surah_content_cubit.dart';

class SurahContentScreen extends StatefulWidget {
  const SurahContentScreen({required this.surah, super.key});

  final SurahModel surah;

  @override
  State<SurahContentScreen> createState() => _SurahContentScreenState();
}

class _SurahContentScreenState extends State<SurahContentScreen> {
  late final SurahContentCubit _cubit;
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completeSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _cubit = SurahContentCubit()
      ..loadContent(
        surahNumber: widget.surah.number,
        pageSize: widget.surah.numberOfAyahs,
      );
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoadingAudio = false;
      });
    });
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xfff4efdc),
        appBar: AppBar(
          backgroundColor: const Color(0xfff4efdc),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_right, color: Color(0xff263238)),
          ),
          // actions: [
          //   IconButton(
          //     tooltip: 'الانتقال إلى صفحة',
          //     onPressed: _showPageJumpDialog,
          //     icon:
          //         const Icon(Icons.bookmark_outline, color: Color(0xff263238)),
          //   ),
          // ],
          title: Column(
            children: [
              Text(
                widget.surah.name.replaceFirst('سُورَةُ ', ''),
                style: TextStyles.blackBold16.copyWith(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 20.sp,
                ),
              ),
              Text(
                '${widget.surah.numberOfAyahs} آيات • ${widget.surah.isMeccan ? 'مكية' : 'مدنية'}',
                style: TextStyles.greyRegular15.copyWith(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<SurahContentCubit, BaseState<AyahModel>>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            if (state.isFailure) {
              return _ContentError(
                message: state.errorMessage,
                onRetry: () => _cubit.loadContent(
                  surahNumber: widget.surah.number,
                  pageSize: widget.surah.numberOfAyahs,
                ),
              );
            }
            if (state.items.isEmpty) {
              return Center(
                child: Text('لا توجد آيات', style: TextStyles.greyRegular15),
              );
            }

            final pages = _groupIntoMushafPages(state.items);
            if (pages.isEmpty) {
              return const _MetadataUnavailable();
            }
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: pages.length,
                    itemBuilder: (context, index) => _QuranPage(
                      ayahs: pages[index].value,
                      surahNumber: widget.surah.number,
                      pageNumber: pages[index].key,
                    ),
                  ),
                ),
                _PageIndicator(
                  controller: _pageController,
                  pageNumbers: pages.map((page) => page.key).toList(),
                ),
                if (_cubit.audioUrl?.trim().isNotEmpty == true)
                  _QuranAudioBar(
                    isPlaying: _isPlaying,
                    isLoading: _isLoadingAudio,
                    position: _position,
                    duration: _duration,
                    onToggle: _toggleAudio,
                    onSeek: _seekAudio,
                  ),
                SizedBox(height: 14.h),
              ],
            );
          },
        ),
        //
      ),
    );
  }

  Future<void> _toggleAudio() async {
    final url = _cubit.audioUrl?.trim();
    if (url == null || url.isEmpty) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isLoadingAudio = true);
    try {
      await _audioPlayer.play(UrlSource(url.replaceAll('`', '')));
      if (mounted) setState(() => _isPlaying = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل السورة')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(milliseconds: value.round());
    await _audioPlayer.seek(position);
    if (mounted) setState(() => _position = position);
  }

  List<MapEntry<int, List<AyahModel>>> _groupIntoMushafPages(
      List<AyahModel> ayahs) {
    final grouped = <int, List<AyahModel>>{};
    for (final ayah in ayahs) {
      final pageNumber = ayah.pageNumber;
      if (pageNumber == null) continue;
      grouped.putIfAbsent(pageNumber, () => <AyahModel>[]).add(ayah);
    }
    return grouped.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
  }

  // Future<void> _showPageJumpDialog() async {
  //   final pageNumbers = _groupIntoMushafPages(_cubit.state.items)
  //       .map((page) => page.key)
  //       .toList();
  //   if (pageNumbers.isEmpty || !mounted) return;

  //   final controller = TextEditingController();
  //   final pageNumber = await showDialog<int>(
  //     context: context,
  //     builder: (context) => Directionality(
  //       textDirection: TextDirection.rtl,
  //       child: AlertDialog(
  //         title: const Text('الانتقال إلى صفحة'),
  //         content: TextField(
  //           controller: controller,
  //           keyboardType: TextInputType.number,
  //           decoration: InputDecoration(
  //             hintText: '${pageNumbers.first} - ${pageNumbers.last}',
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('إلغاء'),
  //           ),
  //           FilledButton(
  //             onPressed: () {
  //               final value = int.tryParse(controller.text);
  //               if (value != null && pageNumbers.contains(value)) {
  //                 Navigator.of(context).pop(value);
  //               }
  //             },
  //             child: const Text('انتقال'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //   controller.dispose();
  //   if (pageNumber == null || !mounted) return;
  //   final index = pageNumbers.indexOf(pageNumber);
  //   if (index >= 0) {
  //     _pageController.animateToPage(index,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOutCubic);
  //   }
  // }
}

class _MushafHeader extends StatelessWidget {
  const _MushafHeader({required this.ayah, required this.pageNumber});

  final AyahModel ayah;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        Text('الجزء ${_arabicDigits(ayah.juz ?? 1)}',
            style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp)),
        Text('صفحة ${_arabicDigits(pageNumber)}',
            style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp)),
      ],
    );
  }
}

class _QuranAudioBar extends StatelessWidget {
  const _QuranAudioBar({
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
  });

  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final durationInMilliseconds = duration.inMilliseconds;
    final positionInMilliseconds =
        position.inMilliseconds.clamp(0, durationInMilliseconds).toDouble();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.fromLTRB(10.w, 5.h, 10.w, 2.h),
      decoration: BoxDecoration(
        color: const Color(0xffe8e1c8),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xffd8cda9)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 3,
                ),
              )
            else
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: AppColors.primaryColor,
                  size: 38,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: TextStyles.greyRegular15
                              .copyWith(fontSize: 11.sp)),
                      Text(isPlaying ? 'الاستماع إلى السورة' : 'السورة',
                          textDirection: TextDirection.rtl,
                          style:
                              TextStyles.blackBold16.copyWith(fontSize: 12.sp)),
                      Text(_formatDuration(duration),
                          style: TextStyles.greyRegular15
                              .copyWith(fontSize: 11.sp)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: AppColors.primaryColor,
                      inactiveTrackColor: const Color(0xffc9d1cc),
                      thumbColor: AppColors.primaryColor,
                    ),
                    child: Slider(
                      value: positionInMilliseconds,
                      min: 0,
                      max: durationInMilliseconds == 0
                          ? 1
                          : durationInMilliseconds.toDouble(),
                      onChanged: durationInMilliseconds == 0 ? null : onSeek,
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    if (name == null || name!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        'سُورَةُ ${name!.replaceFirst('سُورَةُ ', '')}',
        textDirection: TextDirection.rtl,
        style: TextStyles.blackBold16.copyWith(
          fontFamily: 'UthmanicHafs',
          color: AppColors.primaryColor,
          fontSize: 19.sp,
        ),
      ),
    );
  }
}

class _MushafFooter extends StatelessWidget {
  const _MushafFooter({required this.pageNumber, required this.showSajda});

  final int pageNumber;
  final bool showSajda;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        if (showSajda)
          Text('۩ سجدة',
              style: TextStyles.greyRegular15
                  .copyWith(color: AppColors.primaryColor, fontSize: 12.sp))
        else
          const SizedBox.shrink(),
        Text(_arabicDigits(pageNumber),
            style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp)),
      ],
    );
  }
}

String _arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
}

class _QuranPage extends StatelessWidget {
  const _QuranPage({
    required this.ayahs,
    required this.surahNumber,
    required this.pageNumber,
  });

  final List<AyahModel> ayahs;
  final int surahNumber;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final firstAyah = ayahs.first;
    final hasSurahStart = firstAyah.isFirstAyahOfSurah ?? firstAyah.number == 1;
    final showBismillah = hasSurahStart && surahNumber != 9;
    final containsSajda = ayahs.any((ayah) => ayah.sajda);

    return ColoredBox(
      color: const Color(0xfff4efdc),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
        child: Column(
          children: [
            _MushafHeader(ayah: firstAyah, pageNumber: pageNumber),
            if (hasSurahStart) _SurahHeader(name: firstAyah.surahNameArabic),
            if (showBismillah)
              Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 23.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: _FlowingQuranText(
                        ayahs: ayahs,
                        firstAyah: firstAyah,
                        removeLeadingBismillah: showBismillah,
                      ),
                    ),
                  );
                },
              ),
            ),
            _MushafFooter(pageNumber: pageNumber, showSajda: containsSajda),
          ],
        ),
      ),
    );
  }
}

class _FlowingQuranText extends StatelessWidget {
  const _FlowingQuranText({
    required this.ayahs,
    required this.firstAyah,
    required this.removeLeadingBismillah,
  });

  final List<AyahModel> ayahs;
  final AyahModel firstAyah;
  final bool removeLeadingBismillah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Text.rich(
        TextSpan(
          children: [
            for (final ayah in ayahs) ...[
              TextSpan(
                text: _displayText(ayah),
              ),
              TextSpan(
                text: '${ayah.sajda ? ' ۩' : ''} '
                    '${_arabicDigits(ayah.ayahNumberInSurah ?? ayah.number)} ',
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  color: const Color.fromARGB(255, 98, 79, 38),
                  fontSize: 22.sp,
                ),
              ),
            ],
          ],
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 22.sp,
          height: 1.55,
          color: const Color.fromARGB(255, 2, 2, 2),
        ),
      ),
    );
  }

  String _displayText(AyahModel ayah) {
    var text = ayah.arabicText.replaceAll(
      RegExp(r'[۝۞۩٭][٠-٩۰-۹0-9]*'),
      '',
    );
    if (removeLeadingBismillah && identical(ayah, firstAyah)) {
      text = _removeLeadingBismillah(text);
    }
    return text;
  }

  static String _removeLeadingBismillah(String text) {
    const prefixes = [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    ];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) return text.substring(prefix.length).trim();
    }
    return text;
  }
}

class _PageIndicator extends StatefulWidget {
  const _PageIndicator({required this.controller, required this.pageNumbers});

  final PageController controller;
  final List<int> pageNumbers;

  @override
  State<_PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<_PageIndicator> {
  var _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.controller.page?.round() ?? 0;
    if (page != _page && mounted) {
      setState(() => _page = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _page.clamp(0, widget.pageNumbers.length - 1);
    return Text(
      'صفحة ${_arabicDigits(widget.pageNumbers[pageIndex])} / '
      '${_arabicDigits(widget.pageNumbers.last)}',
      style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
    );
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'حدث خطأ أثناء تحميل السورة',
              style: TextStyles.greyRegular15),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

class _MetadataUnavailable extends StatelessWidget {
  const _MetadataUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          'لا يمكن عرض صفحات المصحف لأن استجابة الآيات لا تحتوي على رقم الصفحة. '
          'يجب أن يعيد الخادم الحقل pageNumber لكل آية.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyles.greyRegular15.copyWith(height: 1.7),
        ),
      ),
    );
  }
}
