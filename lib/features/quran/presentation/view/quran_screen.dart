import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_model.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view/surah_content_screen.dart';
import 'package:mushaf_alsawy/features/quran/presentation/view_model/cubit/quran_cubit.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late final QuranCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _cubit = QuranCubit()..loadSurahs();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      _cubit.loadSurahs(search: value, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20.h, bottom: 12.h),
                child: Column(
                  children: [
                    Text('القرآن الكريم', style: TextStyles.blackBold32),
                    SizedBox(height: 2.h),
                    Text('كتاب الله العزيز',
                        style:
                            TextStyles.greyRegular15.copyWith(fontSize: 18.sp)),
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text('۞',
                          style: TextStyle(
                              color: const Color(0xffd5af53), fontSize: 18.sp)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyles.blackBold16
                      .copyWith(color: AppColors.blackColor),
                  decoration: InputDecoration(
                    hintText: 'إبحث عن سورة',
                    hintStyle: TextStyles.blackBold16.copyWith(fontSize: 16.sp),
                    suffixIcon:
                        const Icon(Icons.search, color: Color(0xff687486)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.r),
                      borderSide: const BorderSide(color: Color(0xffe2e2df)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.r),
                      borderSide:
                          const BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 13.h),
              Expanded(
                child: BlocBuilder<QuranCubit, BaseState<SurahModel>>(
                  builder: (context, state) {
                    if (state.isLoading && state.items.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryColor));
                    }
                    if (state.isFailure && state.items.isEmpty) {
                      return _ErrorView(
                          message: state.errorMessage, onRetry: _cubit.retry);
                    }
                    if (state.items.isEmpty) {
                      return Center(
                          child: Text('لا توجد سور',
                              style: TextStyles.greyRegular15));
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 180 &&
                            !state.hasReachedMax) {
                          _cubit.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        itemCount:
                            state.items.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor)),
                            );
                          }
                          return _SurahTile(
                            surah: state.items[index],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SurahContentScreen(
                                  surah: state.items[index],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final SurahModel surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = surah.number.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64.h,
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffe2e2df)))),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: surah.number == 1
                    ? AppColors.primaryColor
                    : AppColors.highlightColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(number,
                  style: TextStyles.blackBold12.copyWith(
                      color: surah.number == 1
                          ? Colors.white
                          : AppColors.primaryColor)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.name.replaceFirst('سُورَةُ ', ''),
                      style: TextStyles.blackBold16.copyWith(
                          fontFamily: 'UthmanicHafs', fontSize: 20.sp)),
                  Text(
                      '${surah.numberOfAyahs} آيات • ${surah.isMeccan ? 'مكية' : 'مدنية'}',
                      style: TextStyles.greyRegular15.copyWith(
                          fontFamily: 'UthmanicHafs', fontSize: 15.sp)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xff6d7b8c), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'حدث خطأ أثناء تحميل السور',
              style: TextStyles.greyRegular15),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
