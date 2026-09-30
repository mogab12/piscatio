import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../data/account/account_repository.dart';
import '../../../data/remote/piscatio_api.dart';
import '../../../domain/models/venue.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/account_controller.dart';

/// One line about the sync, for this screen and the settings row.
String syncStatusLabel(
  AppLocalizations l10n,
  Formatters f,
  Account account,
  SyncHealth health,
  DateTime now,
) {
  switch (health) {
    case SyncHealth.retrying:
      return l10n.accountSyncRetrying;
    case SyncHealth.soon:
      return l10n.accountSyncSoon;
    case SyncHealth.ok:
      final last = account.lastSync;
      if (last == null) return l10n.accountNeverSynced;
      final a = last.toLocal();
      final b = now.toLocal();
      final today = a.year == b.year && a.month == b.month && a.day == b.day;
      return today
          ? l10n.accountSyncedToday(f.time(last))
          : l10n.accountSyncedOn(f.date(last), f.time(last));
  }
}

String accountProblemMessage(AppLocalizations l10n, AccountProblem p) =>
    switch (p) {
      AccountProblem.codeWrong => l10n.accountErrorCodeWrong,
      AccountProblem.codeExpired => l10n.accountErrorCodeExpired,
      AccountProblem.emailInvalid => l10n.accountErrorEmailInvalid,
      AccountProblem.tooMany => l10n.accountErrorTooMany,
      AccountProblem.offline => l10n.accountErrorOffline,
    };

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountTitle)),
      body: switch (account) {
        AsyncData(value: final a?) => _SignedIn(account: a),
        AsyncData() => const _SignIn(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

enum _Step { email, code }

/// Email, then the code it receives. The server address hides under
/// "Server" for people who host their own.
class _SignIn extends ConsumerStatefulWidget {
  const _SignIn();

  @override
  ConsumerState<_SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<_SignIn> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _server = TextEditingController();
  var _step = _Step.email;
  var _busy = false;
  AccountProblem? _problem;
  var _badServer = false;

  @override
  void initState() {
    super.initState();
    _server.text = defaultApiBase;
    ref.read(accountRepositoryProvider).server().then((s) {
      if (mounted) _server.text = s;
    });
    _email.addListener(_changed);
    _code.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _server.dispose();
    super.dispose();
  }

  bool get _emailOk => RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim());

  bool get _codeOk => RegExp(r'^\d{6}$').hasMatch(_code.text.trim());

  Future<void> _run(Future<void> Function() action) async {
    if (!isServerAddress(_server.text)) {
      setState(() => _badServer = true);
      return;
    }
    setState(() {
      _busy = true;
      _badServer = false;
      _problem = null;
    });
    try {
      await action();
    } on AccountFailure catch (e) {
      if (mounted) setState(() => _problem = e.problem);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    await ref
        .read(accountControllerProvider)
        .sendCode(_email.text, server: _server.text);
    _code.clear();
    if (mounted) setState(() => _step = _Step.code);
  });

  Future<void> _verify() => _run(
    () => ref
        .read(accountControllerProvider)
        .verifyCode(_email.text, _code.text, server: _server.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    final onEmail = _step == _Step.email;
    final canAct = !_busy && (onEmail ? _emailOk : _codeOk);
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              12,
              PiscatioSizes.gutter,
              24,
            ),
            children: [
              Text(l10n.accountIntro, style: text.bodyLarge),
              const SizedBox(height: 24),
              if (onEmail)
                TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => canAct ? _sendCode() : null,
                  decoration: InputDecoration(labelText: l10n.accountEmail),
                )
              else ...[
                Text(
                  l10n.accountCodeSent(_email.text.trim()),
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => canAct ? _verify() : null,
                  style: text.headlineMedium!.copyWith(
                    fontFamily: PiscatioFonts.expanded,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(labelText: l10n.accountCode),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : _sendCode,
                      child: Text(l10n.accountResendCode),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _step = _Step.email;
                              _problem = null;
                            }),
                      child: Text(l10n.accountChangeEmail),
                    ),
                  ],
                ),
              ],
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      accountProblemMessage(l10n, _problem!),
                      style: text.bodyLarge!.copyWith(color: error),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Theme(
                // No divider lines around the expansion tile.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(l10n.accountServer),
                  initiallyExpanded: _badServer,
                  children: [
                    TextField(
                      controller: _server,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.accountServer,
                        helperText: l10n.accountServerHint,
                        helperMaxLines: 2,
                        errorText: _badServer
                            ? l10n.accountServerInvalid
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            PiscatioSizes.gutter,
            8,
            PiscatioSizes.gutter,
            16,
          ),
          child: ActionSlab(
            label: onEmail ? l10n.accountSendCode : l10n.accountSignIn,
            onPressed: canAct ? (onEmail ? _sendCode : _verify) : null,
          ),
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerStatefulWidget {
  const _SignedIn({required this.account});

  final Account account;

  @override
  ConsumerState<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends ConsumerState<_SignedIn> {
  var _busy = false;

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await ref.read(accountControllerProvider).signOut();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountDeleteTitle),
        content: Text(l10n.accountDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountControllerProvider).deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on AccountFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(accountProblemMessage(l10n, e.problem))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final health = ref.watch(syncHealthProvider).value ?? SyncHealth.ok;
    final now = ref.watch(clockProvider).now();
    final status = syncStatusLabel(l10n, f, widget.account, health, now);
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PiscatioSizes.gutter,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      health == SyncHealth.retrying
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 32,
                      color: health == SyncHealth.retrying
                          ? scheme.error
                          : scheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.account.email, style: text.titleLarge),
                          const SizedBox(height: 4),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              status,
                              style: text.bodyLarge!.copyWith(
                                color: context.palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  24,
                  PiscatioSizes.gutter,
                  16,
                ),
                child: Text(l10n.accountPrivacyNote, style: text.bodyMedium),
              ),
              if (ref.watch(featureProvider(FeatureFlags.venues)))
                const _ShareInsightsTile(),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.accountSignOut),
                subtitle: Text(l10n.accountSignOutHint),
                enabled: !_busy,
                onTap: _signOut,
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: scheme.error,
                ),
                title: Text(
                  l10n.accountDelete,
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: Text(l10n.accountDeleteHint),
                enabled: !_busy,
                onTap: _delete,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            PiscatioSizes.gutter,
            8,
            PiscatioSizes.gutter,
            16,
          ),
          child: ActionSlab(
            icon: Icons.sync_rounded,
            label: l10n.accountSyncNow,
            onPressed: _busy || health == SyncHealth.soon
                ? null
                : () => ref.read(accountControllerProvider).syncNow(),
          ),
        ),
      ],
    );
  }
}

/// Consent to show venues anonymous totals of the trips linked to them.
class _ShareInsightsTile extends ConsumerWidget {
  const _ShareInsightsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final consent = ref.watch(shareInsightsProvider);
    final value = consent.value;
    return SwitchListTile(
      secondary: const Icon(Icons.storefront_outlined),
      title: Text(l10n.accountShareInsights),
      subtitle: Text(l10n.accountShareInsightsHint),
      isThreeLine: true,
      value: value ?? false,
      onChanged: value == null
          ? null
          : (v) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(accountControllerProvider).setShareInsights(v);
              } on AccountFailure catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(accountProblemMessage(l10n, e.problem)),
                  ),
                );
              }
            },
    );
  }
}
