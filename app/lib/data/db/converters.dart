import 'package:drift/drift.dart';

import '../../domain/models/species.dart';

/// Stores a list of short tokens as a comma-separated string.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      fromDb.isEmpty ? const [] : fromDb.split(',');

  @override
  String toSql(List<String> value) => value.join(',');
}

class HabitatListConverter extends TypeConverter<List<Habitat>, String> {
  const HabitatListConverter();

  @override
  List<Habitat> fromSql(String fromDb) => fromDb.isEmpty
      ? const []
      : [for (final name in fromDb.split(',')) Habitat.values.byName(name)];

  @override
  String toSql(List<Habitat> value) => value.map((h) => h.name).join(',');
}
