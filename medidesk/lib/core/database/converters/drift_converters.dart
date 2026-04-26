import 'dart:convert';
import 'package:drift/drift.dart';

class DateTimeConverter extends TypeConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb);

  @override
  String toSql(DateTime value) => value.toIso8601String();
}

class NullableDateTimeConverter extends TypeConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromSql(String? fromDb) =>
      fromDb == null ? null : DateTime.parse(fromDb);

  @override
  String? toSql(DateTime? value) => value?.toIso8601String();
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is List) return List<String>.from(decoded);
    return [];
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
