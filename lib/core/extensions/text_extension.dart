import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

extension RichTextExtension on TextSpan {
  TextSpan addTextSpan({
    required String text,
    TextStyle? style,
    List<TextSpan>? children,
    GestureRecognizer? recognizer,
    String? semanticsLabel,
  }) {
    return TextSpan(
      text: this.text,
      style: this.style,
      children: [
        if (this.children != null) ...this.children!,
        TextSpan(
          text: text,
          style: style,
          children: children,
          recognizer: recognizer,
          semanticsLabel: semanticsLabel,
        ),
      ],
    );
  }
}