import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/arabic_digits.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/ayah_model.dart';
import 'package:mushaf_alsawy/features/quran/data/mushaf_layout_repository.dart';
import 'package:mushaf_alsawy/features/quran/data/qcf_font_manager.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view/mushaf/mushaf_page_widget.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view_model/cubit/ayah_tafsir_cubit.dart';

/// Shows the ayah (in its Mushaf glyphs) and its tafsir.
Future<void> showTafsirDialog(
  BuildContext context, {
  required int surah,
  required int ayah,
  required int page,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => AyahTafsirCubit()..loadTafsir(surah: surah, ayah: ayah),
      child: _TafsirDialog(surah: surah, ayah: ayah, page: page),
    ),
  );
}

class _TafsirDialog extends StatelessWidget {
  const _TafsirDialog({
    required this.surah,
    required this.ayah,
    required this.page,
  });

  final int surah;
  final int ayah;
  final int page;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<MushafLayoutRepository>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xfffaf6e9),
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 40.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 0.75.sh),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'سورة ${repo.chapter(surah).name} • الآية ${arabicDigits(ayah)}',
                        style: TextStyles.blackBold16
                            .copyWith(color: AppColors.primaryColor),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.greyColor),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xffe3d9b8)),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AyahGlyphs(surah: surah, ayah: ayah, page: page),
                      SizedBox(height: 16.h),
                      Text(
                        'التفسير الميسر',
                        style: TextStyles.blackBold14
                            .copyWith(color: mushafFrameColor),
                      ),
                      SizedBox(height: 6.h),
                      BlocBuilder<AyahTafsirCubit, BaseState<AyahModel>>(
                        builder: (context, state) {
                          if (state.isFailure) {
                            return _TafsirError(
                              message: state.errorMessage,
                              onRetry: () => context
                                  .read<AyahTafsirCubit>()
                                  .loadTafsir(surah: surah, ayah: ayah),
                            );
                          }
                          final tafsir = state.data?.tafsir.trim();
                          if (!state.isSuccess || tafsir == null) {
                            return Padding(
                              padding: EdgeInsets.all(20.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryColor),
                              ),
                            );
                          }
                          return Text(
                            tafsir.isEmpty
                                ? 'لا يوجد تفسير لهذه الآية'
                                : tafsir,
                            textAlign: TextAlign.justify,
                            style: TextStyles.blackRegular16
                                .copyWith(height: 1.9, fontSize: 15.sp),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ayah in the same QCF glyphs as the Mushaf page (no missing marks).
class _AyahGlyphs extends StatefulWidget {
  const _AyahGlyphs({
    required this.surah,
    required this.ayah,
    required this.page,
  });

  final int surah;
  final int ayah;
  final int page;

  @override
  State<_AyahGlyphs> createState() => _AyahGlyphsState();
}

class _AyahGlyphsState extends State<_AyahGlyphs> {
  late final _segments = getIt<MushafLayoutRepository>()
      .ayahSegments(widget.surah, widget.ayah, widget.page);
  late final Future<void> _fontsReady = Future.wait([
    for (final segment in _segments)
      for (final font in {for (final w in segment.words) w.font})
        getIt<QcfFontManager>().ensureFont(font),
  ]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _fontsReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xfff4efdc),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xffe3d9b8)),
          ),
          child: Text.rich(
            // QPC v4 glyphs are bidi-LTR; force them right to left.
            TextSpan(children: [
              const TextSpan(text: MushafLayoutRepository.rtlOverride),
              for (final segment in _segments)
                for (final word in segment.words)
                  TextSpan(
                    text: '${word.code} ',
                    style: TextStyle(
                      fontFamily: QcfFontManager.familyFor(word.font),
                      fontSize: 22.sp,
                      height: 1.9,
                      color:
                          word.isEnd ? mushafAyahMarkerColor : mushafInkColor,
                    ),
                  ),
              const TextSpan(
                text: MushafLayoutRepository.popDirectionalFormatting,
              ),
            ]),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        );
      },
    );
  }
}

class _TafsirError extends StatelessWidget {
  const _TafsirError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message ?? 'تعذر تحميل التفسير',
          textAlign: TextAlign.center,
          style: TextStyles.greyRegular15,
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'إعادة المحاولة',
            style:
                TextStyles.blackBold14.copyWith(color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }
}
