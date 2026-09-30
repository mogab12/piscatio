import 'package:flutter/material.dart';

import '../../../core/formatting/l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../domain/models/enums.dart';

/// Who sees a post and what it says; null when dismissed.
Future<(CardAudience, String)?> showPublishSheet(BuildContext context) =>
    showModalBottomSheet<(CardAudience, String)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => const _PublishSheet(),
    );

class _PublishSheet extends StatefulWidget {
  const _PublishSheet();

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  var _audience = CardAudience.everyone;
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  0,
                  PiscatioSizes.gutter,
                  8,
                ),
                child: Text(
                  l10n.publishTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (final (a, label, help) in [
                (
                  CardAudience.everyone,
                  l10n.publishEveryone,
                  l10n.publishEveryoneHelp,
                ),
                (
                  CardAudience.friends,
                  l10n.publishFriends,
                  l10n.publishFriendsHelp,
                ),
              ])
                ChoiceRow(
                  label: label,
                  description: help,
                  selected: _audience == a,
                  onTap: () => setState(() => _audience = a),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  8,
                  PiscatioSizes.gutter,
                  0,
                ),
                child: TextField(
                  controller: _caption,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.publishCaptionHint,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  8,
                  PiscatioSizes.gutter,
                  16,
                ),
                child: ActionSlab(
                  label: l10n.publishAction,
                  onPressed: () =>
                      Navigator.of(context).pop((_audience, _caption.text)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
