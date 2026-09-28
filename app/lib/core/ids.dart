import 'package:uuid/uuid.dart';

/// Client-side ids: UUID v7 (time ordered), so records created offline on
/// different devices never collide and sort by creation time.
abstract interface class IdGenerator {
  String newId();
}

class UuidV7Generator implements IdGenerator {
  const UuidV7Generator();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v7();
}

/// Deterministic ids for tests: `id-1`, `id-2`…
class SequentialIdGenerator implements IdGenerator {
  var _next = 1;

  @override
  String newId() => 'id-${_next++}';
}
