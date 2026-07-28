import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String price(double value) {
    final formatter = NumberFormat.decimalPatternDigits(decimalDigits: value.truncateToDouble() == value ? 0 : 2);
    return formatter.format(value);
  }

  static String date(DateTime date, String languageCode) {
    final formatter = DateFormat.yMMMd(languageCode == 'ur' ? 'en' : languageCode);
    return formatter.format(date);
  }

  static String dateTime(DateTime date, String languageCode) {
    final formatter = DateFormat.yMMMd(languageCode == 'ur' ? 'en' : languageCode).add_jm();
    return formatter.format(date);
  }

  /// "Today" / "Yesterday" for the last two calendar days, otherwise a
  /// formatted date — used as day-group headers in the rate history feed.
  static String dayLabel(DateTime input, String languageCode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(input.year, input.month, input.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return languageCode == 'ur' ? 'آج' : 'Today';
    if (diff == 1) return languageCode == 'ur' ? 'کل' : 'Yesterday';
    return AppFormatters.date(day, languageCode);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }
}
