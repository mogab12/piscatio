import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'providers.dart';

/// IANA time zone of the device (e.g. `America/Sao_Paulo`), `UTC` if the
/// platform cannot tell.
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object {
    return 'UTC';
  }
});

/// Emits the current time every second, for running timers.
final nowTickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => clock.now(),
  );
});
