import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Text(
            'الأحاديث',
            style: TextStyles.blackBold20.copyWith(
              color: const Color(0xff0b5c32),
              fontSize: 22.sp,
            ),
          ),
        ),
      ),
    );
  }
}
