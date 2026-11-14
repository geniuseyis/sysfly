/// Date, time and money formatting used across the app. English only.
abstract final class Fmt {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', //
  ];

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
  static String month(DateTime d) => _months[d.month - 1];
  static String monthLong(DateTime d) => _monthsLong[d.month - 1];

  /// "Fri, 4 Sep"
  static String dayShort(DateTime d) => '${weekday(d)}, ${d.day} ${month(d)}';

  /// "4 Sep"
  static String dayMonth(DateTime d) => '${d.day} ${month(d)}';

  /// "FRI 4 SEP"
  static String ticketDate(DateTime d) => '${weekday(d)} ${d.day} ${month(d)}'.toUpperCase();

  /// "04 Sep 2026"
  static String full(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${month(d)} ${d.year}';

  /// "September 2026"
  static String monthYear(DateTime d) => '${monthLong(d)} ${d.year}';

  /// "6:05 AM"
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "6:05" and "AM" separately, for the boarding pass.
  static (String, String) timeParts(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return ('$h:${d.minute.toString().padLeft(2, '0')}', d.hour < 12 ? 'AM' : 'PM');
  }

  /// "1h 50m"
  static String duration(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';

  /// "10h 35m", "8 days", "45m"
  static String countdown(Duration d) {
    if (d.isNegative) return 'now';
    if (d.inHours >= 48) return '${d.inDays} days';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  /// "52m ago", "4h ago", "2d ago"
  static String ago(Duration d) {
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  /// "$128.00"
  static String money(int dollars) => '${dollars < 0 ? '-' : ''}\$${_group(dollars.abs())}.00';

  /// "$88"
  static String moneyShort(int dollars) => '${dollars < 0 ? '-' : ''}\$${_group(dollars.abs())}';

  /// "37,000"
  static String number(int value) => _group(value);

  static String _group(int v) {
    final s = v.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Good Morning" / "Good Afternoon" / "Good Evening"
  static String greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
