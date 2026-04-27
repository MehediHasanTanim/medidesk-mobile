import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

const _dhaka = 'Asia/Dhaka';

abstract final class DateFormatter {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// Converts a UTC ISO8601 string to Asia/Dhaka and formats as "dd MMM yyyy, hh:mm a"
  static String toLocalDateTime(String utcIso) {
    final dt = DateTime.parse(utcIso).toUtc();
    final dhaka = tz.getLocation(_dhaka);
    final local = tz.TZDateTime.from(dt, dhaka);
    return _dateTimeFormat.format(local);
  }

  static String toLocalDate(String utcIso) {
    final dt = DateTime.parse(utcIso).toUtc();
    final dhaka = tz.getLocation(_dhaka);
    final local = tz.TZDateTime.from(dt, dhaka);
    return _dateFormat.format(local);
  }

  static String toLocalTime(String utcIso) {
    final dt = DateTime.parse(utcIso).toUtc();
    final dhaka = tz.getLocation(_dhaka);
    final local = tz.TZDateTime.from(dt, dhaka);
    return _timeFormat.format(local);
  }

  /// Format a "YYYY-MM-DD" date string for display
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      return _dateFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format a DateTime to API date string "YYYY-MM-DD"
  static String toApiDate(DateTime dt) => _apiDateFormat.format(dt);

  /// "Today", "Yesterday", or "dd MMM yyyy"
  static String toRelativeDate(String utcIso) {
    final dt = DateTime.parse(utcIso).toUtc();
    final dhaka = tz.getLocation(_dhaka);
    final local = tz.TZDateTime.from(dt, dhaka);
    final now = tz.TZDateTime.now(dhaka);
    final today = tz.TZDateTime(dhaka, now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (local.isAfter(today)) return 'Today';
    if (local.isAfter(yesterday)) return 'Yesterday';
    return _dateFormat.format(local);
  }

  static String formatBdt(double amount) {
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '৳ $formatted';
  }
}
