import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_model.dart';
import 'package:mushaf_alsawy/features/hadith/presentation/view_model/cubit/hadith_details_cubit.dart';

class HadithDetailsScreen extends StatefulWidget {
  const HadithDetailsScreen({required this.hadithId, super.key});

  final int hadithId;

  @override
  State<HadithDetailsScreen> createState() => _HadithDetailsScreenState();
}

class _HadithDetailsScreenState extends State<HadithDetailsScreen> {
  late final HadithDetailsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = HadithDetailsCubit()..loadHadith(widget.hadithId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_right, color: Color(0xff263238))),
          title: BlocBuilder<HadithDetailsCubit, BaseState<HadithModel>>(
            builder: (context, state) => Text(
                state.data == null
                    ? 'الحديث'
                    : 'الحديث ${state.data!.number.toString().padLeft(2, '0')}',
                style: TextStyles.blackBold16.copyWith(fontSize: 17.sp)),
          ),
        ),
        body: BlocBuilder<HadithDetailsCubit, BaseState<HadithModel>>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor));
            }
            if (state.isFailure) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(state.errorMessage ?? 'حدث خطأ أثناء تحميل الحديث',
                    style: TextStyles.greyRegular15),
                TextButton(
                    onPressed: () => _cubit.loadHadith(widget.hadithId),
                    child: const Text('إعادة المحاولة')),
              ]));
            }
            final hadith = state.data;
            if (hadith == null) {
              return Center(
                  child: Text('لا يوجد حديث', style: TextStyles.greyRegular15));
            }
            return _HadithDetailsContent(hadith: hadith);
          },
        ),
      ),
    );
  }
}

class _HadithDetailsContent extends StatefulWidget {
  const _HadithDetailsContent({required this.hadith});

  final HadithModel hadith;

  @override
  State<_HadithDetailsContent> createState() => _HadithDetailsContentState();
}

class _HadithDetailsContentState extends State<_HadithDetailsContent> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoadingAudio = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String? get _audioUrl {
    final value = widget.hadith.audioUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll('`', '');
  }

  Future<void> _toggleAudio() async {
    final url = _audioUrl;
    if (url == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    setState(() => _isLoadingAudio = true);
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل الحديث')),
      );
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(milliseconds: value.round());
    await _audioPlayer.seek(position);
    if (mounted) setState(() => _position = position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hadith = widget.hadith;
    final text = hadith.text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 3.h, 12.w, 20.h),
      children: [
        Text(hadith.matnName,
            textAlign: TextAlign.center,
            style: TextStyles.greyRegular15
                .copyWith(color: AppColors.primaryColor, fontSize: 13.sp)),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 7.h),
            child: Text('۞',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: const Color(0xffd5af53), fontSize: 18.sp))),
        Container(
          padding: EdgeInsets.fromLTRB(17.w, 18.h, 17.w, 21.h),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xffe2e2df))),
          child: Text(text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w400,
                  fontSize: 22.sp,
                  height: 1.8,
                  color: const Color(0xff1c2730))),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
              color: AppColors.highlightColor,
              borderRadius: BorderRadius.circular(9.r)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المصدر',
                style: TextStyles.greyRegular15
                    .copyWith(fontSize: 10.sp, color: const Color(0xff7b8792))),
            SizedBox(height: 2.h),
            Text(hadith.matnName,
                textAlign: TextAlign.right,
                style: TextStyles.blackBold16
                    .copyWith(fontSize: 12.sp, color: AppColors.primaryColor)),
          ]),
        ),
        if (hadith.hasAudio && _audioUrl != null) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 5.h),
            decoration: BoxDecoration(
                color: AppColors.brandBgColor,
                borderRadius: BorderRadius.circular(11.r)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  if (_isLoadingAudio)
                    const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor, strokeWidth: 3),
                    )
                  else
                    IconButton(
                      onPressed: _toggleAudio,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: AppColors.primaryColor,
                        size: 38,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                    ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position),
                                style: TextStyles.greyRegular15
                                    .copyWith(fontSize: 11.sp)),
                            Text(_isPlaying ? 'الاستماع إلى الحديث' : 'الحديث',
                                textDirection: TextDirection.rtl,
                                style: TextStyles.blackBold16
                                    .copyWith(fontSize: 12.sp)),
                            Text(_formatDuration(_duration),
                                style: TextStyles.greyRegular15
                                    .copyWith(fontSize: 11.sp)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                            activeTrackColor: AppColors.primaryColor,
                            inactiveTrackColor: const Color(0xffc9d1cc),
                            thumbColor: AppColors.primaryColor,
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds == 0
                                ? 0
                                : _position.inMilliseconds
                                    .clamp(0, _duration.inMilliseconds)
                                    .toDouble(),
                            min: 0,
                            max: _duration.inMilliseconds == 0
                                ? 1
                                : _duration.inMilliseconds.toDouble(),
                            onChanged: _duration.inMilliseconds == 0
                                ? null
                                : (value) => setState(() => _position =
                                    Duration(milliseconds: value.round())),
                            onChangeEnd: _duration.inMilliseconds == 0
                                ? null
                                : _seekAudio,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
