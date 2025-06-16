import 'package:intl/intl.dart';

class StringUtils {
  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('d MMMM, yyyy').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  static String formatMonthDisplay(String monthYear) {
    final parts = monthYear.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final monthName =
        [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ][monthNum];
    return '$monthName $year';
  }
}
