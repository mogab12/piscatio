import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/app_database.dart';
import '../remote/piscatio_api.dart';
import '../repositories/settings_repository.dart';

/// Where the sign-in token lives: the platform's secure storage (Keystore,
/// Keychain), never the database.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String? token);
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _key = 'piscatio_token';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String? token) => token == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: token);
}

abstract final class AccountKeys {
  static const email = 'account_email';
  static const server = 'account_server';
  static const syncCursor = 'sync_cursor';
  static const lastSyncAt = 'last_sync_at';
  static const secretShared = 'privacy_secret_shared';
}

/// The signed-in account as the app knows it.
class Account {
  const Account({required this.email, required this.server, this.lastSync});

  final String email;
  final String server;
  final DateTime? lastSync;
}

class AccountRepository {
  AccountRepository(this._db, this._settings, this._tokens);

  final AppDatabase _db;
  final SettingsRepository _settings;
  final TokenStore _tokens;

  /// Null when signed out.
  Stream<Account?> watch() => _db
      .select(_db.settings)
      .watch()
      .map((rows) => _account({for (final r in rows) r.key: r.value}));

  Future<Account?> read() async => _account({
    for (final r in await _db.select(_db.settings).get()) r.key: r.value,
  });

  static Account? _account(Map<String, String> s) {
    final email = s[AccountKeys.email];
    if (email == null) return null;
    final last = s[AccountKeys.lastSyncAt];
    return Account(
      email: email,
      server: s[AccountKeys.server] ?? defaultApiBase,
      lastSync: last == null ? null : DateTime.tryParse(last)?.toUtc(),
    );
  }

  Future<String> server() async =>
      await _settings.getRaw(AccountKeys.server) ?? defaultApiBase;

  Future<void> setServer(String url) =>
      _settings.setRaw(AccountKeys.server, url);

  Future<String?> token() => _tokens.read();

  Future<void> signedIn(ApiSession session) async {
    await _tokens.write(session.token);
    await _settings.setRaw(AccountKeys.email, session.email);
  }

  /// Forgets the session; the logbook stays on the phone.
  Future<void> signOut() async {
    await _tokens.write(null);
    for (final key in [
      AccountKeys.email,
      AccountKeys.syncCursor,
      AccountKeys.lastSyncAt,
      AccountKeys.secretShared,
    ]) {
      await _settings.remove(key);
    }
  }

  Future<int> cursor() async =>
      int.tryParse(await _settings.getRaw(AccountKeys.syncCursor) ?? '') ?? 0;

  Future<void> setCursor(int cursor) =>
      _settings.setRaw(AccountKeys.syncCursor, '$cursor');

  Future<void> setLastSync(DateTime at) =>
      _settings.setRaw(AccountKeys.lastSyncAt, at.toUtc().toIso8601String());

  Future<bool> secretShared() async =>
      await _settings.getRaw(AccountKeys.secretShared) == 'true';

  Future<void> setSecretShared() =>
      _settings.setRaw(AccountKeys.secretShared, 'true');
}
