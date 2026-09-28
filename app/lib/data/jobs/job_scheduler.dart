import 'dart:async';

import 'package:flutter/widgets.dart';

import 'job_runner.dart';

/// Decides when to run the queue: at start, when the app comes back to the
/// foreground, when the connection returns, every few minutes while open,
/// and right after new work is enqueued ([kick]). There is no background
/// execution in the MVP: iOS does not guarantee it.
class JobScheduler {
  JobScheduler(
    this._runner, {
    required this._connectionRestored,
    this.period = const Duration(minutes: 15),
  });

  final JobRunner _runner;
  final Stream<void> _connectionRestored;
  final Duration period;

  AppLifecycleListener? _lifecycle;
  StreamSubscription<void>? _connection;
  Timer? _timer;

  void start() {
    if (_timer != null) return;
    _lifecycle = AppLifecycleListener(onResume: kick);
    _connection = _connectionRestored.listen((_) => kick());
    _timer = Timer.periodic(period, (_) => kick());
    kick();
  }

  /// Runs due jobs now; errors are already handled per job.
  void kick() => unawaited(_runner.runDue().catchError((Object _) {}));

  void dispose() {
    _lifecycle?.dispose();
    unawaited(_connection?.cancel());
    _timer?.cancel();
    _timer = null;
  }
}
