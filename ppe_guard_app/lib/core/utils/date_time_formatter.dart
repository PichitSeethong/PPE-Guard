import 'package:intl/intl.dart';

class DateTimeFormatter {
  DateTimeFormatter._();

  static final _dateTime = DateFormat('d MMM yyyy • HH:mm', 'th_TH');
  static final _time = DateFormat('HH:mm', 'th_TH');
  static final _date = DateFormat('d MMM yyyy', 'th_TH');

  static String dateTime(DateTime? value) => value == null ? '-' : _dateTime.format(value.toLocal());
  static String time(DateTime? value) => value == null ? '-' : _time.format(value.toLocal());
  static String date(DateTime? value) => value == null ? '-' : _date.format(value.toLocal());

  static String duration(int? totalSeconds) {
    if (totalSeconds == null) return '-';
    if (totalSeconds < 60) return '$totalSeconds วินาที';
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes นาที';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return remainMinutes == 0 ? '$hours ชั่วโมง' : '$hours ชั่วโมง $remainMinutes นาที';
  }
}
