import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/social.dart';
import '../application/community.dart';

/// The message for a failed community request.
String problemText(BuildContext context, Object error) {
  final l10n = context.l10n;
  return switch (problemOf(error)) {
    CommunityProblem.offline => l10n.communityOffline,
    CommunityProblem.signedOut => l10n.outboxSignedOut,
    CommunityProblem.handleTaken => l10n.profileHandleTaken,
    CommunityProblem.handleReserved => l10n.profileHandleReserved,
    CommunityProblem.handleInvalid => l10n.profileHandleHelp,
    CommunityProblem.profileRequired => l10n.publishNeedsProfile,
    CommunityProblem.notFound || CommunityProblem.other => l10n.communityFailed,
  };
}

/// Runs a community action; a failure becomes a SnackBar.
Future<bool> runCommunityAction(
  BuildContext context,
  Future<void> Function() action, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on CommunityFailure catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(problemText(context, e))));
    }
    return false;
  }
}

/// A round profile picture, or the first letter of the name.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 40,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty
        ? ''
        : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundImage: url == null
            ? null
            : ref.watch(socialImageProvider)(url!),
        onForegroundImageError: url == null ? null : (_, _) {},
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: PiscatioFonts.expanded,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A centered message with an optional action: empty lists, errors, the
/// steps before taking part.
class CommunityMessage extends StatelessWidget {
  const CommunityMessage({
    super.key,
    required this.text,
    this.title,
    this.icon,
    this.action,
    this.onAction,
  });

  final String? title;
  final String text;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PiscatioSizes.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null)
              Icon(icon, size: 56, color: theme.colorScheme.primary),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: context.palette.muted,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              ActionSlab(label: action!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// A failed request with "try again".
class CommunityError extends StatelessWidget {
  const CommunityError({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CommunityMessage(
    icon: Icons.cloud_off_rounded,
    text: problemText(context, error),
    action: context.l10n.communityRetry,
    onAction: onRetry,
  );
}

/// Someone in a list (search, followers, requests).
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.person, this.trailing});

  final SocialProfile person;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: PiscatioSizes.minTouch + 8,
    leading: ProfileAvatar(name: person.displayName, url: person.avatarUrl),
    title: Text(person.displayName),
    subtitle: Text('@${person.handle}'),
    trailing:
        trailing ??
        (person.isPrivate
            ? Icon(
                Icons.lock_outline_rounded,
                semanticLabel: context.l10n.communityPrivateMark,
              )
            : null),
    onTap: () => context.push(AppRoutes.person(person.handle)),
  );
}

Future<bool> confirmCommunity(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ==
    true;

/// Asks why, then reports a post or a profile.
Future<void> reportFlow(
  BuildContext context,
  WidgetRef ref, {
  String? postId,
  String? handle,
}) async {
  final l10n = context.l10n;
  final reason = await showModalBottomSheet<ReportReason>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              0,
              PiscatioSizes.gutter,
              12,
            ),
            child: Text(
              l10n.communityReportTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          for (final (r, label) in [
            (ReportReason.location, l10n.communityReportLocation),
            (ReportReason.abuse, l10n.communityReportAbuse),
            (ReportReason.spam, l10n.communityReportSpam),
            (ReportReason.other, l10n.communityReportOther),
          ])
            ChoiceRow(
              label: label,
              selected: false,
              onTap: () => Navigator.of(context).pop(r),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  await runCommunityAction(
    context,
    () => ref
        .read(communityControllerProvider)
        .report(postId: postId, handle: handle, reason: reason),
    done: l10n.communityReportSent,
  );
}

/// Confirms, then blocks [handle].
Future<bool> blockFlow(
  BuildContext context,
  WidgetRef ref,
  String handle,
) async {
  final l10n = context.l10n;
  final sure = await confirmCommunity(
    context,
    title: l10n.communityBlockTitle(handle),
    body: l10n.communityBlockBody,
    action: l10n.communityBlockAction,
  );
  if (!sure || !context.mounted) return false;
  return runCommunityAction(
    context,
    () => ref.read(communityControllerProvider).block(handle),
    done: l10n.communityBlocked(handle),
  );
}

enum _PostAction { delete, report, block }

/// One published card: who, the card, its caption and likes.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.source});

  final FeedPost post;

  /// The list it is in (see [FeedSource]), to update it in place.
  final String source;

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PostAction action,
  ) async {
    final l10n = context.l10n;
    switch (action) {
      case _PostAction.delete:
        final sure = await confirmCommunity(
          context,
          title: l10n.communityDeletePostTitle,
          body: l10n.communityDeletePostBody,
          action: l10n.communityDeletePost,
        );
        if (!sure || !context.mounted) return;
        await runCommunityAction(
          context,
          () => ref.read(communityControllerProvider).deletePost(post),
        );
      case _PostAction.report:
        await reportFlow(context, ref, postId: post.id);
      case _PostAction.block:
        await blockFlow(context, ref, post.author.handle);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final theme = Theme.of(context);
    final muted = context.palette.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.person(post.author.handle)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(PiscatioSizes.gutter, 8, 4, 8),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: post.author.displayName,
                    url: post.author.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.displayName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${post.author.handle}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_PostAction>(
                    tooltip: l10n.communityMoreOptions,
                    onSelected: (a) => _onAction(context, ref, a),
                    itemBuilder: (context) => [
                      if (post.mine)
                        PopupMenuItem(
                          value: _PostAction.delete,
                          child: Text(l10n.communityDeletePost),
                        )
                      else ...[
                        PopupMenuItem(
                          value: _PostAction.report,
                          child: Text(l10n.communityReport),
                        ),
                        PopupMenuItem(
                          value: _PostAction.block,
                          child: Text(l10n.communityBlock(post.author.handle)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiscatioSizes.gutter,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
              child: AspectRatio(
                aspectRatio: post.aspectRatio,
                child: Semantics(
                  image: true,
                  label: l10n.communityPostLabel(post.author.handle),
                  child: Image(
                    image: ref.watch(socialImageProvider)(post.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) =>
                        ColoredBox(color: theme.colorScheme.surfaceContainer),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, PiscatioSizes.gutter, 0),
            child: Row(
              children: [
                IconButton(
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: PiscatioSizes.minTouch,
                    minHeight: PiscatioSizes.minTouch,
                  ),
                  tooltip: post.liked
                      ? l10n.communityUnlike
                      : l10n.communityLike,
                  isSelected: post.liked,
                  icon: const Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(
                    Icons.favorite_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => runCommunityAction(
                    context,
                    () => ref
                        .read(communityControllerProvider)
                        .like(post, source: source),
                  ),
                ),
                Semantics(
                  label: l10n.communityLikes(post.likeCount),
                  excludeSemantics: true,
                  child: Text(
                    f.number(post.likeCount.toDouble()),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
                if (post.audience == CardAudience.friends)
                  Tooltip(
                    message: l10n.communityFriendsOnly,
                    child: Icon(
                      Icons.group_outlined,
                      color: muted,
                      semanticLabel: l10n.communityFriendsOnly,
                    ),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    f.shortDate(
                      post.createdAt,
                      now: ref.watch(clockProvider).now(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
          if (post.caption != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PiscatioSizes.gutter,
              ),
              child: Text(post.caption!, style: theme.textTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}

/// A list of posts from a [FeedSource], refreshed by pulling down and
/// continued at the end.
class FeedList extends ConsumerWidget {
  const FeedList({
    super.key,
    required this.source,
    required this.empty,
    this.header,
    this.emptyAction,
    this.onEmptyAction,
  });

  final String source;
  final String empty;
  final Widget? header;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider(source));
    Future<void> refresh() => ref.refresh(feedProvider(source).future);
    final Widget body = switch (feed) {
      AsyncData(:final value) when value.posts.isEmpty => SizedBox(
        height: 360,
        child: CommunityMessage(
          text: empty,
          action: emptyAction,
          onAction: onEmptyAction,
        ),
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final post in value.posts) PostCard(post: post, source: source),
          if (value.hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: value.loadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () =>
                          ref.read(feedProvider(source).notifier).loadMore(),
                      child: Text(context.l10n.communityLoadMore),
                    ),
            ),
        ],
      ),
      AsyncError(:final error) => SizedBox(
        height: 360,
        child: CommunityError(
          error: error,
          onRetry: () => ref.invalidate(feedProvider(source)),
        ),
      ),
      _ => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [?header, body],
      ),
    );
  }
}
