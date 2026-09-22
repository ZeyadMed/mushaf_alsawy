import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _cubit = SurahContentCubit()
      ..loadContent(
        surahNumber: widget.surah.number,
        pageSize: widget.surah.numberOfAyahs,
      );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            icon: const Icon(Icons.chevron_right, color: Color(0xff263238)),
          ),
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
                child: CircularProgressIndicator(color: Color(0xff0b5c32)),
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

            final pages = _splitIntoPages(state.items);
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: pages.length,
                    itemBuilder: (context, index) => _QuranPage(
                      ayahs: pages[index],
                      surahNumber: widget.surah.number,
                    ),
                  ),
                ),
                _PageIndicator(
                    controller: _pageController, count: pages.length),
                SizedBox(height: 14.h),
              ],
            );
          },
        ),
      ),
    );
  }

  List<List<AyahModel>> _splitIntoPages(List<AyahModel> ayahs) {
    final pages = <List<AyahModel>>[];
    var page = <AyahModel>[];
    var characterCount = 0;

    for (final ayah in ayahs) {
      final nextCount = characterCount + ayah.arabicText.length;
      if (page.isNotEmpty && nextCount > 420) {
        pages.add(page);
        page = <AyahModel>[];
        characterCount = 0;
      }
      page.add(ayah);
      characterCount += ayah.arabicText.length;
    }
    if (page.isNotEmpty) {
      pages.add(page);
    }
    return pages;
  }
}

class _QuranPage extends StatelessWidget {
  const _QuranPage({required this.ayahs, required this.surahNumber});

  final List<AyahModel> ayahs;
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final displayAyahs = surahNumber == 1 && ayahs.first.number == 1
        ? ayahs.skip(1).toList(growable: false)
        : ayahs;

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xffe2e2df)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Column(
            children: [
              if (ayahs.first.number == 1 && surahNumber != 9)
                Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 23.sp,
                      color: const Color(0xff0b5c32),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: displayAyahs
                      .map((ayah) => _AyahLine(ayah: ayah))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahLine extends StatelessWidget {
  const _AyahLine({required this.ayah});

  final AyahModel ayah;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showTafsir(context),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: ayah.arabicText),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  width: 22.w,
                  height: 22.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xffd9fae8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${ayah.number}',
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      color: const Color(0xff0b5c32),
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 22.sp,
            height: 1.65,
            color: const Color(0xff17212b),
          ),
        ),
      ),
    );
  }

  void _showTafsir(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'تفسير الآية ${ayah.number}',
            style: TextStyles.blackBold16,
          ),
          content: SingleChildScrollView(
            child: Text(
              ayah.tafsir.isEmpty
                  ? 'لا يوجد تفسير متاح لهذه الآية.'
                  : ayah.tafsir,
              style: TextStyles.greyRegular15.copyWith(height: 1.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatefulWidget {
  const _PageIndicator({required this.controller, required this.count});

  final PageController controller;
  final int count;

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
    return Text(
      '${_page + 1} / ${widget.count}',
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
