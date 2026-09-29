import 'dart:math' as math;

import '../../core/clock.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'job_queue.dart';

/// What a handler decided about one attempt.
sealed class JobOutcome {
  const JobOutcome();
}

/// Finished (successfully or with nothing left to do): remove the job.
class JobDone extends JobOutcome {
  const JobDone();
}

/// Not ready yet (e.g. data not published): try again at [when].
class JobRetryAt extends JobOutcome {
  const JobRetryAt(this.at, {this.reason});

  final DateTime at;
  final String? reason;
}

/// Recurring work done for now: run again at [at], with a clean slate.
class JobReschedule extends JobOutcome {
  const JobReschedule(this.at);

  final DateTime at;
}

abstract interface class JobHandler {
  JobKind get kind;

  /// Runs one attempt. Throwing means a transient failure (no network):
  /// the runner retries with exponential backoff.
  Future<JobOutcome> run(JobRow job);

  /// Called when the job is dropped after too many failed attempts.
  Future<void> giveUp(JobRow job);
}

/// Runs due jobs one at a time. Safe to call often (app start, resume,
/// connection back, after enqueueing): overlapping calls are coalesced.
class JobRunner {
  JobRunner(this._queue, List<JobHandler> handlers, this._clock)
    : _handlers = {for (final h in handlers) h.kind: h};

  final JobQueue _queue;
  final Map<JobKind, JobHandler> _handlers;
  final Clock _clock;

  /// Transient failures allowed before giving up (with backoff this spans
  /// more than a week).
  static const maxAttempts = 16;

  Future<void>? _running;
  var _again = false;

  Future<void> runDue() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      for (final job in await _queue.due()) {
        await _runOne(job);
      }
    } while (_again);
  }

  Future<void> _runOne(JobRow job) async {
    final handler = _handlers[job.kind];
    if (handler == null) {
      await _queue.complete(job.id);
      return;
    }
    try {
      switch (await handler.run(job)) {
        case JobDone():
          await _queue.complete(job.id);
        case JobReschedule(:final at):
          await _queue.reschedule(job.id, at);
        case JobRetryAt(:final at, :final reason):
          if (job.attempts + 1 >= maxAttempts) {
            await handler.giveUp(job);
            await _queue.complete(job.id);
          } else {
            await _queue.retryAt(job.id, at, error: reason);
          }
      }
    } on Object catch (e) {
      if (job.attempts + 1 >= maxAttempts) {
        await handler.giveUp(job);
        await _queue.complete(job.id);
        return;
      }
      await _queue.retryAt(
        job.id,
        _clock.now().add(backoff(job.attempts)),
        error: '$e',
      );
    }
  }

  /// 15 min, 30 min, 1 h … capped at 12 h.
  static Duration backoff(int attempts) =>
      Duration(minutes: math.min(15 * math.pow(2, attempts).toInt(), 720));
}
