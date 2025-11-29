import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormatter = DateFormat('dd MMM, hh:mm a');

  static String format(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _fullFormatter.format(dateTime);
  }
}
