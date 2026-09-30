import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/l10n.dart';
import '../../../core/media/photo_source.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../domain/models/social.dart';
import '../application/community.dart';
import 'community_widgets.dart';

/// Sets up the public profile, or changes it: @name, name, about, private
/// or open, photo. Also where the person leaves the community.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return switch (profile) {
      AsyncData(:final value) => _ProfileForm(
        key: ValueKey(value?.handle),
        profile: value,
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: CommunityError(
          error: error,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.profile});

  /// Null when creating.
  final SocialProfile? profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _handle = TextEditingController(text: widget.profile?.handle);
  late final _name = TextEditingController(text: widget.profile?.displayName);
  late final _bio = TextEditingController(text: widget.profile?.bio);
  late var _private = widget.profile?.isPrivate ?? true;
  var _saving = false;
  String? _handleError;

  @override
  void dispose() {
    _handle.dispose();
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _valid =>
      handlePattern.hasMatch(normalizeHandle(_handle.text)) &&
      _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _handleError = null;
    });
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(
            handle: _handle.text,
            displayName: _name.text,
            bio: _bio.text,
            isPrivate: _private,
          );
      if (mounted) context.pop();
    } on CommunityFailure catch (e) {
      if (!mounted) return;
      switch (e.problem) {
        case CommunityProblem.handleTaken:
          setState(() => _handleError = l10n.profileHandleTaken);
        case CommunityProblem.handleReserved:
          setState(() => _handleError = l10n.profileHandleReserved);
        case CommunityProblem.handleInvalid:
          setState(() => _handleError = l10n.profileHandleHelp);
        default:
          messenger.showSnackBar(
            SnackBar(content: Text(problemText(context, e))),
          );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final path = await ref.read(photoSourceProvider).pick(PhotoOrigin.gallery);
    if (path == null || !mounted) return;
    // Re-encoded small, without metadata (no EXIF place reaches anyone).
    final jpeg = await ref.read(avatarEncoderProvider)(path);
    if (jpeg == null || !mounted) return;
    await runCommunityAction(
      context,
      () => ref.read(myProfileProvider.notifier).setAvatar(jpeg),
    );
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    final sure = await confirmCommunity(
      context,
      title: l10n.profileLeaveTitle,
      body: l10n.profileLeaveBody,
      action: l10n.profileLeave,
    );
    if (!sure || !mounted) return;
    final left = await runCommunityAction(
      context,
      () => ref.read(myProfileProvider.notifier).leave(),
    );
    if (left && mounted) context.go(AppRoutes.community);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existing = widget.profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          existing == null ? l10n.profileTitleNew : l10n.profileTitleEdit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          8,
          PiscatioSizes.gutter,
          24,
        ),
        children: [
          if (existing != null) ...[
            Center(
              child: ProfileAvatar(
                name: existing.displayName,
                url: existing.avatarUrl,
                size: 96,
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.profilePhotoChange),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _handle,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_.@]')),
              LengthLimitingTextInputFormatter(31),
            ],
            decoration: InputDecoration(
              labelText: l10n.profileHandle,
              helperText: l10n.profileHandleHelp,
              helperMaxLines: 2,
              errorText: _handleError,
              prefixText: '@',
            ),
            onChanged: (_) => setState(() => _handleError = null),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.profileName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLength: 160,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.profileBio,
              hintText: l10n.profileBioHint,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _private,
            title: Text(l10n.profilePrivate),
            subtitle: Text(l10n.profilePrivateHelp),
            onChanged: (v) => setState(() => _private = v),
          ),
          if (existing != null) ...[
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block_rounded),
              title: Text(l10n.profileBlocked),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.communityBlocked),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.profileLeave,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: _leave,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          8,
          PiscatioSizes.gutter,
          16,
        ),
        child: ActionSlab(
          label: l10n.actionSave,
          onPressed: _valid && !_saving ? _save : null,
        ),
      ),
    );
  }
}
