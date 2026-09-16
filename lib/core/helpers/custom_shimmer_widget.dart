
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmerWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxShape? shape;

  const CustomShimmerWidget({
    super.key,
    this.height = 50,
    this.shape = BoxShape.rectangle,
    this.width = double.infinity,
    this.baseColor,
    this.highlightColor,
  });

  const CustomShimmerWidget.circular({
    super.key,
    this.baseColor,
    this.highlightColor,
    double dimension = 20,
  })  : height = dimension,
        width = dimension,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveBaseColor =
        baseColor ?? (isDarkMode ? Colors.grey[800]! : Colors.grey[300]!);
    final Color effectiveHighlightColor =
        highlightColor ?? (isDarkMode ? Colors.grey[700]! : Colors.white);

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: effectiveBaseColor,
          shape: shape!,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(10),
        ),
      ),
    );
  }
}
