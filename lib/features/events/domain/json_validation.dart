// Shared manual decoding keeps malformed input failures descriptive and typed.
Map<String, dynamic> jsonObject(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be a JSON object');
  }
  return Map<String, dynamic>.from(value);
}

String jsonString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

double jsonNumber(Object? value, String field, {double min = 0, double? max}) {
  if (value is! num) throw FormatException('$field must be a number');
  final number = value.toDouble();
  if (!number.isFinite || number < min || (max != null && number > max)) {
    throw FormatException(
      '$field must be finite and between $min and ${max ?? 'the finite maximum'}',
    );
  }
  return number;
}

int jsonInteger(
  Object? value,
  String field, {
  int min = 0,
  int max = 2147483647,
}) {
  final number = jsonNumber(
    value,
    field,
    min: min.toDouble(),
    max: max.toDouble(),
  );
  if (number != number.truncateToDouble()) {
    throw FormatException('$field must be an integer');
  }
  return number.toInt();
}

bool jsonBool(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean');
  return value;
}

DateTime jsonDate(Object? value, String field) {
  final text = jsonString(value, field);
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(?:Z|([+-])(\d{2}):(\d{2}))?)?$',
  ).firstMatch(text);
  if (match == null)
    throw FormatException('$field must be an ISO Gregorian date');
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final calendar = DateTime.utc(year, month, day);
  if (year < 1 ||
      calendar.year != year ||
      calendar.month != month ||
      calendar.day != day ||
      (match[4] != null &&
          (int.parse(match[4]!) > 23 ||
              int.parse(match[5]!) > 59 ||
              int.parse(match[6]!) > 59)) ||
      (match[9] != null &&
          (int.parse(match[9]!) > 23 || int.parse(match[10]!) > 59))) {
    throw FormatException('$field contains an invalid Gregorian date or time');
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) throw FormatException('$field contains an invalid date');
  return parsed;
}

List<int> clockParts(String time) {
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(time);
  if (match == null)
    throw const FormatException(
      'time must be HH:mm with hours 00–23 and minutes 00–59',
    );
  return [int.parse(match[1]!), int.parse(match[2]!)];
}
