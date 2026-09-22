import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/style/app_text_theme.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

mixin AppThemeData on ThemeData {
  static ThemeData light(BuildContext context) => ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.accentColor,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryColor,
        onSurface: Colors.black,
        onError: Colors.white,
        outlineVariant: AppColors.primaryDarkColor,
        onInverseSurface: Colors.grey[200],
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
      appBarTheme: AppBarTheme(
          color: Colors.white,
          titleTextStyle: AppTextTheme.headlineLarge,
          surfaceTintColor: Colors.white,
          elevation: 0),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accentColor,
        selectionColor: AppColors.accentColor,
        selectionHandleColor: AppColors.accentColor,
      ),
      fontFamily: 'IBM Plex Sans Arabic',
      textTheme: TextTheme(
        bodyLarge: AppTextTheme.bodyLarge,
        bodyMedium: AppTextTheme.bodyMedium,
        bodySmall: AppTextTheme.bodySmall,
        labelLarge: AppTextTheme.labelLarge,
        labelMedium: AppTextTheme.labelMedium,
        labelSmall: AppTextTheme.labelSmall,
        titleLarge: AppTextTheme.titleLarge,
        titleMedium: AppTextTheme.titleMedium,
        titleSmall: AppTextTheme.titleSmall,
        displayLarge: AppTextTheme.displayLarge,
        displayMedium: AppTextTheme.displayMedium,
        displaySmall: AppTextTheme.displaySmall,
        headlineLarge: AppTextTheme.headlineLarge,
        headlineMedium: AppTextTheme.headlineMedium,
        headlineSmall: AppTextTheme.headlineSmall,
      )..apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
          fontFamilyFallback: ['Arial', 'sans-serif'],
          fontFamily: 'IBM Plex Sans Arabic',
        ),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: AppTextTheme.bodyMedium
            .copyWith(color: Colors.red, fontSize: 20.sp),
      ),
      // textSelectionTheme: ,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      // style for dialog action buttons (affects DatePicker confirm/cancel)
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
              TextStyles.blackBold16.copyWith(fontSize: 16.sp)),
          foregroundColor: MaterialStateProperty.all(AppColors.whiteColor),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        cancelButtonStyle: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.red),
          textStyle: MaterialStateProperty.all(TextStyles.blackBold16
              .copyWith(fontSize: 16.sp, color: AppColors.redColor2)),
        ),
        confirmButtonStyle: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(AppColors.primaryColor),
            textStyle: WidgetStateProperty.all(TextStyles.darkBold16)),
        shadowColor: Colors.grey.withOpacity(0.5),
        backgroundColor: Colors.white,
        // dayStyle shouldn't force a single color so we can control
        // selected/disabled colors via the MaterialStateProperty resolvers below.
        dayStyle: TextStyles.blackBold16,
        // Controls the text color for day cells depending on state.
        dayForegroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            // selected day -> primary-colored text
            return AppColors.primaryColor;
          }
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey;
          }
          // default day text color
          return Colors.black;
        }),
        // Controls the background color for day cells depending on state.
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            // make selected day background white (even if it's from previous/next month)
            return Colors.white;
          }
          // default transparent background
          return Colors.transparent;
        }),
        yearStyle: TextStyles.blackBold16,
        dividerColor: AppColors.primaryColor,
        rangePickerHeaderBackgroundColor: AppColors.primaryColor,

        // header (month/year) styles
        headerHelpStyle: TextStyles.darkBold20.copyWith(color: Colors.white),
        headerBackgroundColor: AppColors.primaryColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: TextStyles.blackBold20
            .copyWith(fontSize: 18.sp, color: AppColors.primaryColor),
        rangeSelectionBackgroundColor: AppColors.primaryColor.withOpacity(0.25),
        surfaceTintColor: AppColors.primaryColor,
        todayBackgroundColor:
            MaterialStateProperty.all<Color>(AppColors.primaryColor),
        todayForegroundColor: MaterialStateProperty.all<Color>(Colors.white),
        dayOverlayColor: MaterialStateProperty.all<Color>(
            AppColors.primaryColor.withOpacity(0.1)),
        rangePickerHeaderHelpStyle: TextStyles.whiteBold15,
        rangePickerHeaderForegroundColor: Colors.white,
        rangePickerHeaderHeadlineStyle: TextStyles.whiteBold15,
        rangePickerSurfaceTintColor: AppColors.primaryColor,
        yearOverlayColor: MaterialStateProperty.all<Color>(
            AppColors.primaryColor.withOpacity(0.1)),
        yearForegroundColor: MaterialStateProperty.all<Color>(Colors.black),
        rangeSelectionOverlayColor: MaterialStateProperty.all<Color>(
            AppColors.primaryColor.withOpacity(0.1)),
        // dayBackgroundColor: MaterialStateProperty.all<Color>(Colors.white),
        weekdayStyle: TextStyles.darkBold18,
        todayBorder: BorderSide(
          color: AppColors.primaryColor,
          width: 2.w,
        ),
        // rangePickerHeaderHelpStyle: TextStyles.whiteBold15,
        // dayForegroundColor: MaterialStateProperty.all<Color>(Colors.white),
        // dayBackgroundColor: MaterialStateProperty.all<Color>(AppColors.primaryColor),
        rangePickerBackgroundColor: AppColors.primaryColor,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1,
            ),
          ),
        ),
      ));
}
