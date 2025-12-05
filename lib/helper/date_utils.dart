DateTime addMonths(DateTime date, int months) {
  final int newMonth = date.month + months;
  int year = date.year + (newMonth - 1) ~/ 12;
  int month = ((newMonth - 1) % 12) + 1;

  int daysInTargetMonth(int y, int m) {
    final nextMonth = m == 12 ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int day = date.day;
  final maxDay = daysInTargetMonth(year, month);
  if (day > maxDay) day = maxDay;
  return DateTime(year, month, day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
}
