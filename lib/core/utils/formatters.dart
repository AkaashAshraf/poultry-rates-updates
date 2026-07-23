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

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }
}
