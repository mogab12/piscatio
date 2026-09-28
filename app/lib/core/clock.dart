/// Source of the current time. Always UTC. Injected so tests control time.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  FixedClock(DateTime time) : _time = time.toUtc();

  DateTime _time;

  void advance(Duration by) => _time = _time.add(by);

  void set(DateTime time) => _time = time.toUtc();

  @override
  DateTime now() => _time;
}
