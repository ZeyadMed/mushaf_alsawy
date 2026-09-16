import 'package:flutter/services.dart';

class HMIFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-numeric characters

    if (text.length > 6) {
      return oldValue; // Prevent entering more than HHMMSS
    }

    String formatted = _formatTime(text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatTime(String input) {
    if (input.isEmpty) return "";

    List<String> parts = [];
    for (int i = 0; i < input.length; i++) {
      if (i == 2 || i == 4) parts.add(':'); // Insert colons at correct positions
      parts.add(input[i]);
    }

    String result = parts.join('');

    // Ensure valid ranges for hours, minutes, and seconds
    List<String> timeParts = result.split(':');
    if (timeParts.isNotEmpty && timeParts[0].length == 2) {
      int hours = int.parse(timeParts[0]);
      if (hours > 23) timeParts[0] = '23'; // Max 23 hours
    }
    if (timeParts.length > 1 && timeParts[1].length == 2) {
      int minutes = int.parse(timeParts[1]);
      if (minutes > 59) timeParts[1] = '59'; // Max 59 minutes
    }
    if (timeParts.length > 2 && timeParts[2].length == 2) {
      int seconds = int.parse(timeParts[2]);
      if (seconds > 59) timeParts[2] = '59'; // Max 59 seconds
    }

    return timeParts.join(':');
  }
}
