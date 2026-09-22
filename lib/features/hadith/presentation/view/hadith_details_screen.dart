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
                  child: CircularProgressIndicator(color: Color(0xff0b5c32)));
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

class _HadithDetailsContent extends StatelessWidget {
  const _HadithDetailsContent({required this.hadith});

  final HadithModel hadith;

  @override
  Widget build(BuildContext context) {
    final text = hadith.text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 3.h, 12.w, 20.h),
      children: [
        Text(hadith.matnName,
            textAlign: TextAlign.center,
            style: TextStyles.greyRegular15
                .copyWith(color: const Color(0xff0b5c32), fontSize: 13.sp)),
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
                  fontFamily: 'UthmanicHafs',
                  fontSize: 22.sp,
                  height: 1.8,
                  color: const Color(0xff1c2730))),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
              color: const Color(0xffd9fae8),
              borderRadius: BorderRadius.circular(9.r)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المصدر',
                style: TextStyles.greyRegular15
                    .copyWith(fontSize: 10.sp, color: const Color(0xff7b8792))),
            SizedBox(height: 2.h),
            Text(hadith.matnName,
                textAlign: TextAlign.right,
                style: TextStyles.blackBold16
                    .copyWith(fontSize: 12.sp, color: const Color(0xff0b5c32))),
          ]),
        ),
        if (hadith.hasAudio && hadith.audioUrl != null) ...[
          SizedBox(height: 16.h),
          Container(
              height: 66.h,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: const Color(0xfff0f5f1),
                  borderRadius: BorderRadius.circular(11.r)),
              child: Row(children: [
                const Icon(Icons.play_circle_fill,
                    color: Color(0xff0b5c32), size: 38),
                SizedBox(width: 10.w),
                Text('الاستماع إلى الحديث',
                    style: TextStyles.blackBold16.copyWith(fontSize: 13.sp)),
              ])),
        ],
      ],
    );
  }
}
