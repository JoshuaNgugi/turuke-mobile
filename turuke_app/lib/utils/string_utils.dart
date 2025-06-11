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
}
