import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_matn_model.dart';
import 'package:mushaf_alsawy/features/hadith/presentation/view/hadith_list_screen.dart';
import 'package:mushaf_alsawy/features/hadith/presentation/view_model/cubit/hadith_matns_cubit.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  late final HadithMatnsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = HadithMatnsCubit()..loadMatns();
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
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 18.h, bottom: 12.h),
                child: Column(
                  children: [
                    Text('الأحاديث النبوية',
                        style:
                            TextStyles.blackBold32.copyWith(fontSize: 22.sp)),
                    SizedBox(height: 2.h),
                    Text('من هدي النبي ﷺ',
                        style:
                            TextStyles.greyRegular15.copyWith(fontSize: 15.sp)),
                    Padding(
                      padding: EdgeInsets.only(top: 7.h),
                      child: Text('۞',
                          style: TextStyle(
                              color: const Color(0xffd5af53), fontSize: 18.sp)),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text('المجموعات',
                      style: TextStyles.blackBold16.copyWith(fontSize: 15.sp)),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child:
                    BlocBuilder<HadithMatnsCubit, BaseState<HadithMatnModel>>(
                  builder: (context, state) {
                    if (state.isLoading) return const _HadithLoading();
                    if (state.isFailure) {
                      return _HadithError(
                          message: state.errorMessage,
                          onRetry: _cubit.loadMatns);
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final matn = state.items[index];
                        return _MatnCard(
                          matn: matn,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                            builder: (_) => HadithListScreen(matn: matn),
                          )),
                        );
                      },
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

class _MatnCard extends StatelessWidget {
  const _MatnCard({required this.matn, required this.onTap});

  final HadithMatnModel matn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.r),
          child: Container(
            height: 78.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: const Color(0xffe2e2df)),
            ),
            child: Row(
              children: [
                   Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                      color: const Color(0xffd9fae8),
                      borderRadius: BorderRadius.circular(9.r)),
                  child: const Icon(Icons.article_outlined,
                      color: Color(0xff0b5c32)),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(matn.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyles.blackBold16.copyWith(fontSize: 15.sp)),
                      SizedBox(height: 3.h),
                      Text('مجموعة من الأحاديث النبوية الشريفة',
                          style: TextStyles.greyRegular15
                              .copyWith(fontSize: 11.sp)),
                      Text('${matn.hadithsCount} حديث',
                          style: TextStyles.greyRegular15.copyWith(
                              color: const Color(0xff0b5c32), fontSize: 10.sp)),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
             
                const Icon(Icons.chevron_right, color: Color(0xff6d7b8c)),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HadithLoading extends StatelessWidget {
  const _HadithLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Color(0xff0b5c32)));
}

class _HadithError extends StatelessWidget {
  const _HadithError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message ?? 'حدث خطأ أثناء تحميل المجموعات',
            style: TextStyles.greyRegular15),
        TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ]));
}
