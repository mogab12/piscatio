import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/db/app_database.dart';
import '../data/repositories/settings_repository.dart';
import '../data/seed/species_seeder.dart';
import '../l10n/generated/app_localizations.dart';
import 'clock.dart';
import 'providers.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/brand.dart';

/// What the app is doing before its first real screen.
enum BootStep { database, catalog }

typedef DatabaseOpener = Future<AppDatabase> Function(
  void Function(BootStep step) onStep,
);

/// Opens the on-device database (running any migration) and applies the
/// species catalog.
Future<AppDatabase> openAppDatabase(void Function(BootStep) onStep) async {
  onStep(BootStep.database);
  final db = AppDatabase.open();
  try {
    // Forces the file to open and migrations to run now, not on first use.
    await db.customSelect('SELECT 1').get();
    onStep(BootStep.catalog);
    await SpeciesSeeder(
      db,
      SettingsRepository(db),
      const SystemClock(),
    ).apply(await rootBundle.loadString('assets/seed/species.json'));
    return db;
  } catch (_) {
    await db.close();
    rethrow;
  }
}

/// Shows the app right away and prepares the database behind a boot
/// screen. Startup never blocks `main()`: if opening fails the screen says
/// what went wrong, and if it takes long it says which step is slow.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    super.key,
    this.open = openAppDatabase,
    this.app = _defaultApp,
    this.slowAfter = const Duration(seconds: 12),
  });

  final DatabaseOpener open;
  final Widget Function(AppDatabase db) app;
  final Duration slowAfter;

  static Widget _defaultApp(AppDatabase db) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const PiscatioApp(),
  );

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AppDatabase? _db;
  BootStep? _step;
  Object? _error;
  StackTrace? _stack;
  var _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _stack = null;
      _slow = false;
      _step = null;
    });
    _slowTimer?.cancel();
    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    try {
      final db = await widget.open((step) {
        if (mounted) setState(() => _step = step);
      });
      if (!mounted) return;
      setState(() => _db = db);
    } on Object catch (e, st) {
      debugPrint('Startup failed: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e;
          _stack = st;
        });
      }
    } finally {
      _slowTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = _db;
    if (db != null) return widget.app(db);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _BootScreen(
        step: _step,
        slow: _slow,
        error: _error,
        stack: _stack,
        onRetry: _start,
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({
    required this.step,
    required this.slow,
    required this.error,
    required this.stack,
    required this.onRetry,
  });

  final BootStep? step;
  final bool slow;
  final Object? error;
  final StackTrace? stack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge!.copyWith(color: PiscatioColors.reedOnDark);
    final failed = error != null;
    final details = failed ? '$error\n\n${_shortStack(stack)}' : null;
    return Scaffold(
      backgroundColor: PiscatioColors.deepWater,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PiscatioSizes.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const BrandLockup(size: 40, tagline: true),
              const SizedBox(height: 24),
              if (!failed) ...[
                Text(switch (step) {
                  BootStep.catalog => l10n.bootStepCatalog,
                  _ => l10n.bootStepDatabase,
                }, style: muted),
                if (slow) ...[
                  const SizedBox(height: 8),
                  Text(l10n.bootSlow, style: text.bodyLarge),
                ],
                const Spacer(),
              ] else ...[
                Text(l10n.bootFailedTitle, style: text.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.bootFailedBody, style: muted),
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      details!,
                      style: text.bodySmall!.copyWith(
                        color: PiscatioColors.foam,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onRetry,
                        child: Text(l10n.bootRetry),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: details)),
                        child: Text(l10n.bootCopyDetails),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _shortStack(StackTrace? st) =>
      (st?.toString() ?? '').split('\n').take(12).join('\n');
}

/// In release builds a broken widget shows its error message (so a
/// screenshot is enough to diagnose it) instead of an empty grey box.
void installReadableErrorWidget() {
  if (kDebugMode) return;
  ErrorWidget.builder = (details) => ColoredBox(
    color: PiscatioColors.deepWater,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        details.exceptionAsString(),
        textDirection: TextDirection.ltr,
        style: const TextStyle(color: PiscatioColors.foam, fontSize: 12),
      ),
    ),
  );
}
