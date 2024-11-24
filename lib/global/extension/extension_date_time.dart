

import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String get formatDateFromIso => DateFormat('dd/MM/yyyy').format(this);
}