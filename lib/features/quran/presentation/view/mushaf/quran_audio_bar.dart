import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mushaf_alsawy/core/style/app_colors.dart';
import 'package:mushaf_alsawy/core/theme/text_styles.dart';

class QuranAudioBar extends StatelessWidget {
  const QuranAudioBar({
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
    this.title = 'السورة',
    super.key,
  });

  final String title;

  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;

  /// Null while the surah's recitation is unavailable.
  final VoidCallback? onToggle;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final durationInMilliseconds = duration.inMilliseconds;
    final positionInMilliseconds =
        position.inMilliseconds.clamp(0, durationInMilliseconds).toDouble();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.fromLTRB(10.w, 5.h, 10.w, 2.h),
      decoration: BoxDecoration(
        color: const Color(0xffe8e1c8),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xffd8cda9)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // The button's tap target (48), so the bar keeps its height
            // while loading and the Mushaf pages above never resize.
            SizedBox.square(
              dimension: 48,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: onToggle == null
                            ? AppColors.greyColor
                            : AppColors.primaryColor,
                        size: 38,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                    ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: TextStyles.greyRegular15
                              .copyWith(fontSize: 11.sp)),
                      Text(isPlaying ? 'الاستماع إلى $title' : title,
                          textDirection: TextDirection.rtl,
                          style:
                              TextStyles.blackBold16.copyWith(fontSize: 12.sp)),
                      Text(_formatDuration(duration),
                          style: TextStyles.greyRegular15
                              .copyWith(fontSize: 11.sp)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: AppColors.primaryColor,
                      inactiveTrackColor: const Color(0xffc9d1cc),
                      thumbColor: AppColors.primaryColor,
                    ),
                    child: Slider(
                      value: positionInMilliseconds,
                      min: 0,
                      max: durationInMilliseconds == 0
                          ? 1
                          : durationInMilliseconds.toDouble(),
                      onChanged: durationInMilliseconds == 0 ? null : onSeek,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
