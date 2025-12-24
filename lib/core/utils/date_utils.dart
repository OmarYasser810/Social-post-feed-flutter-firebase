import 'package:timeago/timeago.dart' as timeago;

class DateUtils {
  static String timeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'en_short');
  }
  
  static String formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}