import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mushaf_alsawy/core/helpers/label.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Widget? icon;
  final Widget? trailingIcon;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double iconSpacing;
  final VoidCallback onPressed;
  final bool? isIcon;
  final double? fontSize;
  final FontWeight? fontWeight;

  CustomButton({
    super.key,
    this.title = "",
    this.icon,
    this.trailingIcon,
    Color? backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(15),
    required this.onPressed,
    this.iconBackgroundColor = AppColors.whiteColor,
    this.isIcon = false,
    this.fontSize,
    this.borderColor,
    this.fontWeight,
    this.width,
    this.height,
    this.gradient,
    this.boxShadow,
    this.iconSpacing = 10,
  }) : backgroundColor = backgroundColor ?? AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          padding: padding,
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: gradient == null ? backgroundColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
            boxShadow: boxShadow,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((isIcon ?? false) && icon != null) ...[
                  SizedBox(width: 8.w),
                  icon!,
                  Gap(iconSpacing),
                ],
                LocalizedLabel(
                  text: title,
                  style: TextStyles.darkBold16.copyWith(
                    color: textColor,
                    fontWeight: fontWeight ?? FontWeight.w700,
                    fontSize: fontSize ?? 16.spMax,
                  ),
                ),
                if (trailingIcon != null) ...[
                  Gap(iconSpacing),
                  trailingIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
