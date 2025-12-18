import 'package:intl/intl.dart';

final _format = DateFormat("yyyy-MM-dd HH:mm:ss");

String formatDate(DateTime date) {
  return _format.format(date);
}
