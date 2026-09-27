/// Converts Western digits to Arabic-Indic digits (e.g. 604 → ٦٠٤).
String arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
}
