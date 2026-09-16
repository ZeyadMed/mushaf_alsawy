import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract interface class AppTextTheme {
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: 'Alexandria',
    // letterSpacing: 0.5,
    color: Color.fromRGBO(0, 0, 0, 1)
  );

  static TextStyle heading1 = _baseStyle.copyWith(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle heading2 = _baseStyle.copyWith(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle body1 = _baseStyle.copyWith(
    fontSize: 16.sp,
  );

  static TextStyle body2 = _baseStyle.copyWith(
    fontSize: 14.sp,
  );

  static TextStyle caption = _baseStyle.copyWith(
    fontSize: 12.sp,
  );

  static TextStyle bodyLarge = _baseStyle.copyWith(
    fontSize: 30.sp,
  );

  static TextStyle bodyMedium = _baseStyle.copyWith(
    fontSize: 25.sp,
  );

  static TextStyle bodySmall = _baseStyle.copyWith(
    fontSize: 14.sp,
  );

  static TextStyle labelLarge = _baseStyle.copyWith(
    fontSize: 14.sp,
  );

  static TextStyle labelMedium = _baseStyle.copyWith(
    fontSize: 12.sp,
  );

  static TextStyle labelSmall = _baseStyle.copyWith(
    fontSize: 10.sp,
  );
static TextStyle titleLarge = _baseStyle.copyWith(
  fontSize: 22.sp,
);

static TextStyle titleMedium = _baseStyle.copyWith(
  fontSize: 20.sp,
);

static TextStyle titleSmall = _baseStyle.copyWith(
  fontSize: 18.sp,
);

static TextStyle displayLarge = _baseStyle.copyWith(
  fontSize: 34.sp,
);

static TextStyle displayMedium = _baseStyle.copyWith(
  fontSize: 28.sp,
);

static TextStyle displaySmall = _baseStyle.copyWith(
  fontSize: 22.sp,
);

static TextStyle headlineLarge = _baseStyle.copyWith(
  fontSize: 32.sp,
);

static TextStyle headlineMedium = _baseStyle.copyWith(
  fontSize: 28.sp,
);

static TextStyle headlineSmall = _baseStyle.copyWith(
  fontSize: 24.sp,
);
}