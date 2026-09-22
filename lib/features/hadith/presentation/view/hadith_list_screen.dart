import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_matn_model.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_model.dart';
import 'package:mushaf_alsawy/features/hadith/presentation/view/hadith_details_screen.dart';
import 'package:mushaf_alsawy/features/hadith/presentation/view_model/cubit/hadith_list_cubit.dart';

class HadithListScreen extends StatefulWidget {
  const HadithListScreen({required this.matn, super.key});

  final HadithMatnModel matn;

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  late final HadithListCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _cubit = HadithListCubit(matnId: widget.matn.id)
      ..loadHadiths(refresh: true);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _search(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      _cubit.loadHadiths(search: value, refresh: true);
    });
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
          title: Text(widget.matn.name,
              style: TextStyles.blackBold16.copyWith(fontSize: 17.sp)),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 5.h, 18.w, 12.h),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyles.blackBold16.copyWith(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'ابحث في الأحاديث',
                  hintStyle: TextStyles.greyRegular15.copyWith(fontSize: 12.sp),
                  suffixIcon:
                      const Icon(Icons.search, color: Color(0xff687486)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.r),
                      borderSide: const BorderSide(color: Color(0xffe2e2df))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.r),
                      borderSide:
                          const BorderSide(color: AppColors.primaryColor)),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<HadithListCubit, BaseState<HadithModel>>(
                builder: (context, state) {
                  if (state.isLoading && state.items.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryColor));
                  }
                  if (state.isFailure && state.items.isEmpty) {
                    return _ListError(
                        message: state.errorMessage, onRetry: _cubit.retry);
                  }
                  if (state.items.isEmpty) {
                    return Center(
                        child: Text('لا توجد أحاديث',
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
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor)));
                        }
                        final hadith = state.items[index];
                        return _HadithCard(
                          hadith: hadith,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => HadithDetailsScreen(
                                      hadithId: hadith.id))),
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
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith, required this.onTap});

  final HadithModel hadith;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = hadith.text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 100.h),
            padding: EdgeInsets.fromLTRB(14.w, 11.h, 14.w, 12.h),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(color: const Color(0xffe2e2df))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('الحديث ${hadith.number.toString().padLeft(2, '0')}',
                        style: TextStyles.greyRegular15.copyWith(
                            fontSize: 11.sp, color: const Color(0xff496079))),
                    const Spacer(),
                    if (hadith.hasAudio)
                      const Icon(Icons.volume_up,
                          size: 16, color: AppColors.primaryColor),
                    if (hadith.hasAudio) SizedBox(width: 6.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                      decoration: BoxDecoration(
                          color: AppColors.highlightColor,
                          borderRadius: BorderRadius.circular(12.r)),
                      child: Text(hadith.grade ?? 'صحيح',
                          style: TextStyles.greyRegular15.copyWith(
                              color: AppColors.primaryColor, fontSize: 10.sp)),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontSize: 17.sp,
                        height: 1.55,
                        color: const Color(0xff25313b))),
                SizedBox(height: 5.h),
                Text('رواه ${hadith.matnName}',
                    textAlign: TextAlign.right,
                    style: TextStyles.greyRegular15.copyWith(
                        fontSize: 10.sp, color: const Color(0xff7c8794))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message ?? 'حدث خطأ أثناء تحميل الأحاديث',
            style: TextStyles.greyRegular15),
        TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ]));
}
