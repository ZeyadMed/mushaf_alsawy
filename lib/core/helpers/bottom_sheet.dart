// bottom_sheet_helper.dart
import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  double maxHeightFactor = 0.9,
  bool isScrollControlled = true,
}) {
  final mediaQuery = MediaQuery.of(context);
  final keyboardHeight = mediaQuery.viewInsets.bottom;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    constraints: BoxConstraints(
      maxHeight: mediaQuery.size.height * maxHeightFactor + keyboardHeight,
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: mediaQuery.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // const Divider(height: 0),
            // Content
            Flexible(
              child: child,
            ),
          ],
        ),
      );
    },
  );
}
