extension DateTimeExtensions on DateTime {
  DateTime startOfDay() {
    return DateTime.utc(year, month, day);
  }
}
