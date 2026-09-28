import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/active_trip/presentation/active_trip_screen.dart';
import '../../features/cards/presentation/card_editor_screen.dart';
import '../../features/history/presentation/catch_detail_screen.dart';
import '../../features/history/presentation/edit_trip_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/history/presentation/trip_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/quick_catch/presentation/quick_catch_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/summary/presentation/trip_summary_screen.dart';
import '../providers.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when onboarding completes (or data is wiped).
  final onboardingDone = ValueNotifier<bool?>(
    ref.read(settingsProvider).value?.onboardingCompleted,
  );
  ref
    ..listen(
      settingsProvider.select((s) => s.value?.onboardingCompleted),
      (_, next) => onboardingDone.value = next,
    )
    ..onDispose(onboardingDone.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: onboardingDone,
    redirect: (context, state) {
      final done = onboardingDone.value;
      if (done == null) return null;
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!done && !atOnboarding) return AppRoutes.onboarding;
      if (done && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.activeTrip,
        builder: (context, state) => const ActiveTripScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/capture/:tripId',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: QuickCatchScreen(tripId: state.pathParameters['tripId']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/trip/:tripId',
        builder: (context, state) =>
            TripDetailScreen(tripId: state.pathParameters['tripId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                EditTripScreen(tripId: state.pathParameters['tripId']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/summary/:tripId',
        builder: (context, state) =>
            TripSummaryScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/cards/trip/:tripId',
        builder: (context, state) => CardEditorScreen(
          subject: CardSubject.trip,
          id: state.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/cards/catch/:catchId',
        builder: (context, state) => CardEditorScreen(
          subject: CardSubject.catchItem,
          id: state.pathParameters['catchId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/catch/:catchId',
        builder: (context, state) =>
            CatchDetailScreen(catchId: state.pathParameters['catchId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
