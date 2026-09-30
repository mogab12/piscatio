import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/providers.dart';
import '../../../data/db/tables.dart';
import '../../../data/jobs/sync_job.dart';
import '../../../data/remote/piscatio_api.dart';

/// Why a request to the server did not work, for the message on screen.
enum AccountProblem { codeWrong, codeExpired, emailInvalid, tooMany, offline }

class AccountFailure implements Exception {
  const AccountFailure(this.problem);

  final AccountProblem problem;

  @override
  String toString() => 'AccountFailure($problem)';
}

/// Whether [text] can be a server address (http or https, with a host).
bool isServerAddress(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// Signing in with a code sent by email, syncing, signing out and deleting
/// the account. The logbook on the phone never depends on any of it.
class AccountController {
  AccountController(this._ref);

  final Ref _ref;

  PiscatioApi _api(String server, [String? token]) =>
      _ref.read(apiFactoryProvider)(server.trim(), token);

  Future<T> _guard<T>(
    Future<T> Function() call, {
    AccountProblem rejected = AccountProblem.codeWrong,
  }) async {
    try {
      return await call();
    } on ApiRejected catch (e) {
      throw AccountFailure(switch (e.code) {
        'code_invalid' => AccountProblem.codeWrong,
        'code_expired' => AccountProblem.codeExpired,
        _ when e.status == 400 => rejected,
        _ => AccountProblem.offline,
      });
    } on ApiUnavailable catch (e) {
      throw AccountFailure(
        e.detail == 429 ? AccountProblem.tooMany : AccountProblem.offline,
      );
    } on ApiSignedOut {
      throw const AccountFailure(AccountProblem.offline);
    } on ArgumentError {
      // An address the HTTP client cannot use.
      throw const AccountFailure(AccountProblem.offline);
    }
  }

  Future<void> sendCode(String email, {required String server}) => _guard(
    () => _api(server).startEmailSignIn(email.trim()),
    rejected: AccountProblem.emailInvalid,
  );

  Future<void> verifyCode(
    String email,
    String code, {
    required String server,
  }) async {
    final session = await _guard(
      () => _api(server).verifyEmailCode(
        email.trim(),
        code.trim(),
        device: defaultTargetPlatform.name,
      ),
    );
    final accounts = _ref.read(accountRepositoryProvider);
    await accounts.setServer(server.trim());
    await accounts.signedIn(session);
    await _ref.read(backgroundWorkProvider).syncSoon();
  }

  Future<void> syncNow() => _ref.read(backgroundWorkProvider).syncSoon();

  /// The consent to share anonymous totals with venues, as the server has
  /// it (the server is the one that uses it).
  Future<bool> shareInsights() async {
    final (server, token) = await _session();
    return _guard(() => _api(server, token).shareInsights());
  }

  Future<void> setShareInsights(bool share) async {
    final (server, token) = await _session();
    await _guard(() => _api(server, token).setShareInsights(share));
    _ref.invalidate(shareInsightsProvider);
  }

  Future<(String, String)> _session() async {
    final accounts = _ref.read(accountRepositoryProvider);
    final account = await accounts.read();
    final token = await accounts.token();
    if (account == null || token == null) {
      throw const AccountFailure(AccountProblem.offline);
    }
    return (account.server, token);
  }

  /// Ends the session here; the logbook stays on the phone.
  Future<void> signOut() async {
    final accounts = _ref.read(accountRepositoryProvider);
    final account = await accounts.read();
    final token = await accounts.token();
    if (account != null && token != null) {
      try {
        // Best effort: without the token here the session is gone anyway.
        await _api(
          account.server,
          token,
        ).signOut().timeout(const Duration(seconds: 5));
      } on Object {
        // Offline or the server is down: sign out here regardless.
      }
    }
    await _forget();
  }

  /// Erases the account and everything on the server. The logbook on the
  /// phone stays.
  Future<void> deleteAccount() async {
    final accounts = _ref.read(accountRepositoryProvider);
    final account = await accounts.read();
    final token = await accounts.token();
    if (account != null && token != null) {
      await _guard(() => _api(account.server, token).deleteAccount());
    }
    await _forget();
  }

  Future<void> _forget() async {
    await _ref.read(backgroundWorkProvider).cancelSync();
    await _ref.read(accountRepositoryProvider).signOut();
    await _ref.read(syncServiceProvider).forgetServer();
  }
}

final accountControllerProvider = Provider(AccountController.new);

/// The insights consent, read from the server when the screen asks.
final shareInsightsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(accountControllerProvider).shareInsights(),
);

/// What the account screen says about syncing.
enum SyncHealth {
  /// Nothing to report: synced, next round later.
  ok,

  /// Asked for and about to run.
  soon,

  /// The last try failed (offline, server down): it retries by itself.
  retrying,
}

/// Read from the recurring sync job.
final syncHealthProvider = StreamProvider<SyncHealth>((ref) {
  final clock = ref.watch(clockProvider);
  return ref.watch(jobQueueProvider).watch(JobKind.sync, syncSubject).map((
    job,
  ) {
    if (job == null) return SyncHealth.ok;
    if (job.attempts > 0) return SyncHealth.retrying;
    return job.nextAttemptAt.isAfter(clock.now())
        ? SyncHealth.ok
        : SyncHealth.soon;
  });
});
