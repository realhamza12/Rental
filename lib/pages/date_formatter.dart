import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats a DateTime to "d MMM" format (e.g., "10 May")
  static String formatToShortDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('d MMM').format(dateTime);
  }

  /// Formats a range of dates to "d MMM to d MMM" format (e.g., "10 May to 15 May")
  static String formatDateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return '';
    return '${formatToShortDate(from)} to ${formatToShortDate(to)}';
  }

  /// Formats a DateTime to include day of week "EEE, d MMM" (e.g., "Mon, 10 May")
  static String formatWithDayOfWeek(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('EEE, d MMM').format(dateTime);
  }
}