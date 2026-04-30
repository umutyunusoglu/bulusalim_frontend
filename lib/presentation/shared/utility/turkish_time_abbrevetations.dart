import 'package:timeago/timeago.dart' as timeago;

class TurkishTimeAbbreviations implements timeago.LookupMessages {
  // ... (Önceki kod ile aynı)
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'şimdi';
  @override
  String aboutAMinute(int minutes) => '1dk';
  @override
  String minutes(int minutes) => '${minutes}dk';
  @override
  String aboutAnHour(int minutes) => '1sa';
  @override
  String hours(int hours) => '${hours}sa';
  @override
  String aDay(int hours) => '1gn';
  @override
  String days(int days) => '${days}gn';
  @override
  String aboutAMonth(int days) => '1ay';
  @override
  String months(int months) => '${months}ay';
  @override
  String aboutAYear(int year) => '1yl';
  @override
  String years(int years) => '${years}yl';
  @override
  String wordSeparator() => ' ';
}
