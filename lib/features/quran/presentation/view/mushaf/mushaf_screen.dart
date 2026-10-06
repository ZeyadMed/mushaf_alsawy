import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/helpers/arabic_digits.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/mushaf_layout_model.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_content_response.dart';
import 'package:mushaf_alsawy/features/quran/data/mushaf_layout_repository.dart';
import 'package:mushaf_alsawy/features/quran/data/qcf_font_manager.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view/mushaf/mushaf_page_widget.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view/mushaf/quran_audio_bar.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view/mushaf/tafsir_dialog.dart';

const Color _paperColor = Color.fromARGB(255, 250, 249, 247);

/// The whole Madina Mushaf (604 pages), opened at [initialSurah]'s first page.
class MushafScreen extends StatefulWidget {
  const MushafScreen({required this.initialSurah, super.key});

  final int initialSurah;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _repo = getIt<MushafLayoutRepository>();
  final _fonts = getIt<QcfFontManager>();
  late final Future<void> _layoutReady;
  PageController? _pageController;

  /// Built once: rebuilding the screen (page counter, audio) leaves the
  /// pages alone.
  Widget? _pager;
  final ValueNotifier<String?> _selectedAyah = ValueNotifier(null);
  final ValueNotifier<int> _currentPage = ValueNotifier(1);

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<int, String?> _audioUrls = {};
  final Set<int> _fetchingAudio = {};
  int? _audioSurah;
  Duration _duration = Duration.zero;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _layoutReady = _repo.load().then((_) {
      if (!mounted) return;
      final page = _repo.startPageOf(widget.initialSurah);
      _pageController = PageController(initialPage: page - 1);
      _onPageChanged(page - 1);
      _prefetchAround(page);
    });
    _subscriptions.addAll([
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoadingAudio = false;
        });
      }),
      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      }),
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) _position.value = position;
      }),
      _audioPlayer.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() => _isPlaying = false);
        _position.value = Duration.zero;
      }),
    ]);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _selectedAyah.dispose();
    _currentPage.dispose();
    _position.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Called mid-swipe, so it only updates the counter and the audio bar.
  void _onPageChanged(int index) {
    final page = index + 1;
    _currentPage.value = page;
    final surah = _repo.page(page).firstSurah;
    // Keep the playing surah until the user stops it.
    if (!_isPlaying && surah != _audioSurah) _switchAudioSurah(surah);
  }

  /// Registering a font and measuring a page wait for the swipe to end, so
  /// that their work does not land on the frames of the page animation.
  bool _onScrollEnd(ScrollEndNotification notification) {
    if (notification.depth == 0) _prefetchAround(_currentPage.value);
    return false;
  }

  /// Loads the fonts of the pages around [page], mostly ahead in reading
  /// order: a font covers ~13 pages, so a new one is ready a few pages before
  /// it is needed. Also measures, between frames, the pages the next swipe
  /// builds (the ones beside [page] are already built).
  void _prefetchAround(int page) {
    bool exists(int p) => p >= 1 && p <= MushafLayoutRepository.totalPages;
    _fonts.prefetch({
      for (var p = page - 2; p <= page + 5; p++)
        if (exists(p)) ..._repo.fontsOf(p),
    });
    for (final p in [page + 2, page - 2]) {
      if (!exists(p)) continue;
      SchedulerBinding.instance.scheduleTask(
        () => precacheMushafPage(_repo.page(p)),
        // Not idle: that waits for every animation (a loading spinner) to end.
        Priority.animation,
      );
    }
  }

  Future<void> _switchAudioSurah(int surah) async {
    setState(() => _audioSurah = surah);
    if (_position.value != Duration.zero) {
      await _audioPlayer.stop();
      if (!mounted) return;
      _position.value = Duration.zero;
      _duration = Duration.zero;
    }
    if (_audioUrls.containsKey(surah) || !_fetchingAudio.add(surah)) return;
    final result =
        await GenericDataSource(getIt()).fetchResult<SurahContentResponse>(
      endpoint: Endpoints.surahContent(surah),
      queryParameters: {'number': surah, 'pageIndex': 1, 'pageSize': 1},
      fromJson: SurahContentResponse.fromJson,
    );
    _fetchingAudio.remove(surah);
    result.fold((_) {}, (response) {
      final url = response.audioUrl?.replaceAll('`', '').trim();
      _audioUrls[surah] = url == null || url.isEmpty ? null : url;
    });
    if (mounted) setState(() {});
  }

  String? get _audioUrl => _audioUrls[_audioSurah];

  Future<void> _toggleAudio() async {
    final url = _audioUrl;
    if (url == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isLoadingAudio = true);
    try {
      if (_position.value == Duration.zero) {
        await _audioPlayer.play(UrlSource(url));
      } else {
        await _audioPlayer.resume();
      }
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
    if (mounted) _position.value = position;
  }

  Future<void> _onAyahTap(MushafWord word, MushafPage page) async {
    _selectedAyah.value = word.verseKey;
    await showTafsirDialog(
      context,
      surah: word.surah,
      ayah: word.ayah,
      page: page.number,
    );
    if (mounted) _selectedAyah.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _paperColor,
        // appBar: AppBar(
        //   backgroundColor: _paperColor,
        //   surfaceTintColor: _paperColor,
        //   elevation: 0,
        //   centerTitle: true,
        //   leading: IconButton(
        //     onPressed: () => Navigator.of(context).pop(),
        //     icon: const Icon(Icons.chevron_right, color: Color(0xff263238)),
        //   ),
        //   title: _repo.layout == null ? null : _buildTitle(),
        // ),
        body: FutureBuilder<void>(
          future: _layoutReady,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child:
                    Text('تعذر تحميل المصحف', style: TextStyles.greyRegular15),
              );
            }
            final controller = _pageController;
            if (controller == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            return Column(
              children: [
                Expanded(child: _pager ??= _buildPager(controller)),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (context, page, _) => Text(
                      'صفحة ${arabicDigits(page)} / ${arabicDigits(MushafLayoutRepository.totalPages)}',
                      textDirection: TextDirection.rtl,
                      style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
                    ),
                  ),
                ),
                // Always shown, so the pages never change size (and relayout)
                // while a surah's recitation loads.
                ValueListenableBuilder<Duration>(
                  valueListenable: _position,
                  builder: (context, position, _) {
                    final surah = _audioSurah;
                    return QuranAudioBar(
                      title: surah == null
                          ? 'السورة'
                          : 'سورة ${_repo.chapter(surah).name}',
                      isPlaying: _isPlaying,
                      isLoading:
                          _isLoadingAudio || _fetchingAudio.contains(surah),
                      position: position,
                      duration: _duration,
                      onToggle: _audioUrl == null ? null : _toggleAudio,
                      onSeek: _seekAudio,
                    );
                  },
                ),
                SizedBox(height: 10.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPager(PageController controller) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      // RTL like a paper Mushaf: the next page comes in from the left.
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: controller,
          // Keeps the pages on either side built, so a swipe only shows them.
          allowImplicitScrolling: true,
          itemCount: MushafLayoutRepository.totalPages,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) => MushafPageWidget(
            page: _repo.page(index + 1),
            selectedAyah: _selectedAyah,
            onAyahTap: _onAyahTap,
          ),
        ),
      ),
    );
  }

  // Widget _buildTitle() {
  //   final chapter = _repo.chapter(_repo.page(_currentPage).firstSurah);
  //   return Column(
  //     children: [
  //       Text(
  //         'سورة ${arabicDigits(chapter.number)}: ${chapter.name}',
  //         style: TextStyles.blackBold16.copyWith(
  //           fontFamily: 'UthmanicHafs',
  //           fontSize: 20.sp,
  //         ),
  //       ),
  //       Text(
  //         '${arabicDigits(chapter.versesCount)} آية • ${chapter.isMeccan ? 'مكية' : 'مدنية'}',
  //         textDirection: TextDirection.rtl,
  //         style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
  //       ),
  //     ],
  //   );
  // }
}
