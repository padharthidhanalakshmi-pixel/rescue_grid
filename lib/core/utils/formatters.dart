import 'package:intl/intl.dart';

class Fmt {
  Fmt._();
  static String time(DateTime t) => DateFormat('hh:mm:ss a').format(t);
  static String shortTime(DateTime t) => DateFormat('hh:mm a').format(t);
  static String dateTime(DateTime t) => DateFormat('dd MMM, hh:mm a').format(t);

  static String mmss(int seconds) {
    final s0 = seconds < 0 ? 0 : seconds;
    final m = (s0 ~/ 60).toString().padLeft(2, '0');
    final s = (s0 % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String duration(Duration? d) => d == null ? '--:--' : mmss(d.inSeconds);

  static String distance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';

  static String etaMinutes(int seconds) {
    final m = (seconds / 60).ceil();
    return '${m.toString().padLeft(2, '0')} min';
  }

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
