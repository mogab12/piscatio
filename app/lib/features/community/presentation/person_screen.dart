import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/social.dart';
import '../application/community.dart';
import 'community_widgets.dart';

enum _PersonAction { block, unblock, report, removeFollower }

/// Someone's public profile (or the person's own): who they are, how many
/// follow them, the follow button and their posts when visible.
class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.handle});

  final String handle;

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PersonAction action,
  ) async {
    final community = ref.read(communityControllerProvider);
    switch (action) {
      case _PersonAction.block:
        await blockFlow(context, ref, handle);
      case _PersonAction.unblock:
        await runCommunityAction(context, () => community.unblock(handle));
      case _PersonAction.report:
        await reportFlow(context, ref, handle: handle);
      case _PersonAction.removeFollower:
        await runCommunityAction(
          context,
          () => community.removeFollower(handle),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final person = ref.watch(personProvider(handle));
    final profile = person.value;
    final rel = profile?.relationship;
    return Scaffold(
      appBar: AppBar(
        title: Text('@$handle'),
        actions: [
          if (rel != null)
            PopupMenuButton<_PersonAction>(
              tooltip: l10n.communityMoreOptions,
              onSelected: (a) => _onAction(context, ref, a),
              itemBuilder: (context) => [
                if (rel.followsYou)
                  PopupMenuItem(
                    value: _PersonAction.removeFollower,
                    child: Text(l10n.communityRemoveFollower),
                  ),
                PopupMenuItem(
                  value: _PersonAction.report,
                  child: Text(l10n.communityReportProfile),
                ),
                if (rel.blocked)
                  PopupMenuItem(
                    value: _PersonAction.unblock,
                    child: Text(l10n.communityUnblock),
                  )
                else
                  PopupMenuItem(
                    value: _PersonAction.block,
                    child: Text(l10n.communityBlock(handle)),
                  ),
              ],
            ),
        ],
      ),
      body: switch (person) {
        AsyncData(:final value) =>
          value.canSee
              ? FeedList(
                  source: FeedSource.person(handle),
                  header: _Header(profile: value),
                  empty: l10n.communityNoPosts,
                )
              : ListView(
                  children: [
                    _Header(profile: value),
                    Padding(
                      padding: const EdgeInsets.all(PiscatioSizes.gutter),
                      child: CommunityMessage(
                        icon: Icons.lock_outline_rounded,
                        text: l10n.communityPrivateProfile,
                      ),
                    ),
                  ],
                ),
        AsyncError(:final error) => CommunityError(
          error: error,
          onRetry: () => ref.invalidate(personProvider(handle)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile});

  final SocialProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final theme = Theme.of(context);
    final rel = profile.relationship;
    final handle = profile.handle;
    final community = ref.read(communityControllerProvider);

    Widget stat(int count, String label, VoidCallback? onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PiscatioSizes.minTouch),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                f.number(count.toDouble()),
                style: const TextStyle(
                  fontFamily: PiscatioFonts.expanded,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final (
      String label,
      bool filled,
      Future<void> Function() action,
    ) = switch (rel) {
      null => (
        l10n.communityEditProfile,
        false,
        () async => context.push(AppRoutes.communityProfile),
      ),
      Relationship(blocked: true) => (
        l10n.communityUnblock,
        false,
        () => community.unblock(handle),
      ),
      Relationship(following: FollowState.accepted) => (
        l10n.communityFollowing,
        false,
        () => community.unfollow(handle),
      ),
      Relationship(following: FollowState.pending) => (
        l10n.communityRequested,
        false,
        () => community.unfollow(handle),
      ),
      Relationship(followsYou: true) => (
        l10n.communityFollowBack,
        true,
        () async => community.follow(handle),
      ),
      _ => (l10n.communityFollow, true, () async => community.follow(handle)),
    };
    const buttonSize = Size.fromHeight(PiscatioSizes.minTouch);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        8,
        PiscatioSizes.gutter,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: profile.displayName,
                url: profile.avatarUrl,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      '@$handle',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                    if (rel != null && (rel.friends || rel.followsYou))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          rel.friends
                              ? l10n.communityFriends
                              : l10n.communityFollowsYou,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(profile.bio, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              stat(
                profile.posts,
                l10n.communityPostsCount(profile.posts),
                null,
              ),
              stat(
                profile.followers,
                l10n.communityFollowersCount(profile.followers),
                profile.canSee
                    ? () => context.push(AppRoutes.followers(handle))
                    : null,
              ),
              stat(
                profile.following,
                l10n.communityFollowingCount,
                profile.canSee
                    ? () => context.push(AppRoutes.following(handle))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filled)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => runCommunityAction(context, action),
              child: Text(label),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => runCommunityAction(context, action),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
