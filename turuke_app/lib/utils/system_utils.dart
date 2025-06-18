class SystemUtils {
  static List<String> generateAvailableMonths() {
    List<String> _availableMonths = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      // For the last 12 months including current
      final monthDateTime = DateTime(now.year, now.month - i, 1);
      // Format as YYYY-MM
      _availableMonths.add(
        '${monthDateTime.year}-${monthDateTime.month.toString().padLeft(2, '0')}',
      );
    }
    return _availableMonths;
  }
}
