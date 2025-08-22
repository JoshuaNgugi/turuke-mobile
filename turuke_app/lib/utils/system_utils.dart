import 'package:flutter/material.dart';

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

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Ensure the context is still valid before showing the SnackBar
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white, // Default to white text
          ),
        ),
        backgroundColor:
            backgroundColor ??
            Colors.grey.shade800, // Default to dark grey background
        duration: duration,
        behavior: SnackBarBehavior.floating, // Makes it float above content
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        margin: const EdgeInsets.all(16), // Margin from screen edges
      ),
    );
  }

  static void showEmptyFlocksWarning(BuildContext context) {
    SystemUtils.showSnackBar(
      context,
      'No flocks available. Please add a flock before adding record.',
    );
  }
}
