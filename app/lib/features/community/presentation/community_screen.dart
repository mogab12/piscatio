import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/background.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/social.dart';
import '../application/community.dart';
import 'community_widgets.dart';

/// The community tab: the feed of people the person follows and a feed to
/// discover others. Before that, the steps to take part (an account, a
/// profile), each explained.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final account = ref.watch(accountProvider);
    final profile = ref.watch(myProfileProvider);
    final me = profile.value;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.communityTitle),
          actions: me == null
              ? null
              : [
                  IconButton(
                    tooltip: l10n.communitySearchPeople,
                    icon: const Icon(Icons.person_search_outlined),
                    onPressed: () => context.push(AppRoutes.communitySearch),
                  ),
                  IconButton(
                    tooltip: l10n.communityRequests,
                    icon: Badge(
                      isLabelVisible: me.requests > 0,
                      label: Text('${me.requests}'),
                      child: const Icon(Icons.how_to_reg_outlined),
                    ),
                    onPressed: () => context.push(AppRoutes.communityRequests),
                  ),
                  IconButton(
                    tooltip: l10n.communityMyProfile,
                    icon: ProfileAvatar(
                      name: me.displayName,
                      url: me.avatarUrl,
                      size: 32,
                    ),
                    onPressed: () => context.push(AppRoutes.person(me.handle)),
                  ),
                ],
          bottom: me == null
              ? null
              : TabBar(
                  tabs: [
                    Tab(text: l10n.communityTabFollowing),
                    Tab(text: l10n.communityTabDiscover),
                  ],
                ),
        ),
        body: switch ((account, profile)) {
          (AsyncData(value: null), _) => CommunityMessage(
            icon: Icons.groups_outlined,
            title: l10n.communitySignInTitle,
            text: l10n.communitySignInBody,
            action: l10n.accountSignIn,
            onAction: () => context.push(AppRoutes.account),
          ),
          (_, AsyncError(:final error)) => CommunityError(
            error: error,
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
          (_, AsyncData(value: null)) => CommunityMessage(
            icon: Icons.badge_outlined,
            title: l10n.communityCreateTitle,
            text: l10n.communityCreateBody,
            action: l10n.communityCreateAction,
            onAction: () => context.push(AppRoutes.communityProfile),
          ),
          (_, AsyncData()) => Column(
            children: [
              const _OutboxBanner(),
              Expanded(
                child: TabBarView(
                  children: [
                    FeedList(
                      source: FeedSource.following,
                      empty: l10n.communityFeedEmpty,
                      emptyAction: l10n.communitySearchPeople,
                      onEmptyAction: () =>
                          context.push(AppRoutes.communitySearch),
                    ),
                    FeedList(
                      source: FeedSource.discover,
                      empty: l10n.communityDiscoverEmpty,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Cards on their way up, and those the server refused (with what to do).
class _OutboxBanner extends ConsumerWidget {
  const _OutboxBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final posts = ref.watch(outboxProvider).value ?? const <OutboxPost>[];
    if (posts.isEmpty) return const SizedBox.shrink();
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        children: [
          for (final post in posts)
            Padding(
              padding: const EdgeInsets.fromLTRB(PiscatioSizes.gutter, 8, 8, 8),
              child: post.error == null
                  ? Row(
                      children: [
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.outboxSending)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.outboxFailed} ${switch (post.error) {
                            'profile_required' => l10n.outboxNeedsProfile,
                            'signed_out' => l10n.outboxSignedOut,
                            'unavailable' => l10n.outboxUnavailable,
                            _ => l10n.outboxRefused,
                          }}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => ref
                                  .read(communityControllerProvider)
                                  .discardPost(post.id),
                              child: Text(l10n.outboxDiscard),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(communityControllerProvider)
                                  .retryPost(post.id),
                              child: Text(l10n.communityRetry),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
