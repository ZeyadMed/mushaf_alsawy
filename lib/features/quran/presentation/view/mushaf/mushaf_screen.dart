import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
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

const Color _paperColor = Color(0xfff4efdc);

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
  final ValueNotifier<String?> _selectedAyah = ValueNotifier(null);
  int _currentPage = 1;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<int, String?> _audioUrls = {};
  int? _audioSurah;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _layoutReady = _repo.load().then((_) {
      final page = _repo.startPageOf(widget.initialSurah);
      _pageController = PageController(initialPage: page - 1);
      _onPageChanged(page - 1);
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
        if (mounted) setState(() => _position = position);
      }),
      _audioPlayer.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }),
    ]);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _selectedAyah.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    _fonts.prefetch([
      for (final p in [page, page + 1, page - 1, page + 2, page - 2])
        if (p >= 1 && p <= MushafLayoutRepository.totalPages)
          ..._repo.fontsOf(p),
    ]);
    final surah = _repo.page(page).firstSurah;
    setState(() => _currentPage = page);
    // Keep the playing surah until the user stops it.
    if (!_isPlaying && surah != _audioSurah) _switchAudioSurah(surah);
  }

  Future<void> _switchAudioSurah(int surah) async {
    _audioSurah = surah;
    if (_position != Duration.zero) {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
    }
    if (_audioUrls.containsKey(surah)) return;
    final result =
        await GenericDataSource(getIt()).fetchResult<SurahContentResponse>(
      endpoint: Endpoints.surahContent(surah),
      queryParameters: {'number': surah, 'pageIndex': 1, 'pageSize': 1},
      fromJson: SurahContentResponse.fromJson,
    );
    result.fold((_) {}, (response) {
      final url = response.audioUrl?.replaceAll('`', '').trim();
      _audioUrls[surah] = url == null || url.isEmpty ? null : url;
      if (mounted) setState(() {});
    });
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
      if (_position == Duration.zero) {
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
    if (mounted) setState(() => _position = position);
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
                Expanded(
                  // RTL like a paper Mushaf: the next page comes in from the left.
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: MushafLayoutRepository.totalPages,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) => MushafPageWidget(
                        page: _repo.page(index + 1),
                        selectedAyah: _selectedAyah,
                        onAyahTap: _onAyahTap,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'صفحة ${arabicDigits(_currentPage)} / ${arabicDigits(MushafLayoutRepository.totalPages)}',
                    textDirection: TextDirection.rtl,
                    style: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
                  ),
                ),
                if (_audioUrl != null)
                  QuranAudioBar(
                    title: 'سورة ${_repo.chapter(_audioSurah!).name}',
                    isPlaying: _isPlaying,
                    isLoading: _isLoadingAudio,
                    position: _position,
                    duration: _duration,
                    onToggle: _toggleAudio,
                    onSeek: _seekAudio,
                  ),
                SizedBox(height: 10.h),
              ],
            );
          },
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
