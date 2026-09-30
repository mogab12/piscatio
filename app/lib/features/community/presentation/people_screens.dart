import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/l10n.dart';
import '../../../domain/models/social.dart';
import '../application/community.dart';
import 'community_widgets.dart';

/// Finds people by name or @name.
class PeopleSearchScreen extends ConsumerStatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  ConsumerState<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends ConsumerState<PeopleSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  var _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _search = text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = ref.watch(peopleSearchProvider(_search));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.communitySearchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: _changed,
          onSubmitted: (text) {
            _debounce?.cancel();
            setState(() => _search = text.trim());
          },
        ),
      ),
      body: _search.length < 2
          ? const SizedBox.shrink()
          : _PeopleList(
              people: results,
              empty: l10n.communitySearchEmpty,
              onRetry: () => ref.invalidate(peopleSearchProvider(_search)),
            ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.people,
    required this.empty,
    required this.onRetry,
    this.trailing,
  });

  final AsyncValue<List<SocialProfile>> people;
  final String empty;
  final VoidCallback onRetry;
  final Widget Function(SocialProfile)? trailing;

  @override
  Widget build(BuildContext context) => switch (people) {
    AsyncData(:final value) when value.isEmpty => CommunityMessage(text: empty),
    AsyncData(:final value) => ListView(
      children: [
        for (final p in value)
          PersonTile(person: p, trailing: trailing?.call(p)),
      ],
    ),
    AsyncError(:final error) => CommunityError(error: error, onRetry: onRetry),
    _ => const Center(child: CircularProgressIndicator()),
  };
}

/// People waiting for the person to let them follow.
class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final community = ref.read(communityControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.communityRequests)),
      body: _PeopleList(
        people: ref.watch(followRequestsProvider),
        empty: l10n.communityRequestsEmpty,
        onRetry: () => ref.invalidate(followRequestsProvider),
        trailing: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => runCommunityAction(
                context,
                () => community.answer(p.handle, accept: false),
              ),
              child: Text(l10n.communityDecline),
            ),
            FilledButton(
              onPressed: () => runCommunityAction(
                context,
                () => community.answer(p.handle, accept: true),
              ),
              child: Text(l10n.communityAccept),
            ),
          ],
        ),
      ),
    );
  }
}

/// Someone's followers, or the people they follow.
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.handle,
    required this.followers,
  });

  final String handle;
  final bool followers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = followListProvider((handle, followers));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          followers
              ? l10n.communityFollowersTitle
              : l10n.communityFollowingTitle,
        ),
      ),
      body: _PeopleList(
        people: ref.watch(provider),
        empty: l10n.communityListEmpty,
        onRetry: () => ref.invalidate(provider),
      ),
    );
  }
}

/// The people the person blocked, to unblock them.
class BlockedPeopleScreen extends ConsumerWidget {
  const BlockedPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileBlocked)),
      body: _PeopleList(
        people: ref.watch(blockedPeopleProvider),
        empty: l10n.profileBlockedEmpty,
        onRetry: () => ref.invalidate(blockedPeopleProvider),
        trailing: (p) => TextButton(
          onPressed: () => runCommunityAction(
            context,
            () => ref.read(communityControllerProvider).unblock(p.handle),
          ),
          child: Text(l10n.communityUnblock),
        ),
      ),
    );
  }
}
