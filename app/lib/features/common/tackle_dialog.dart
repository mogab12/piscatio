import 'package:flutter/material.dart';

import '../../core/formatting/l10n.dart';

/// What the tackle dialog returns.
class TackleEdit<T> {
  const TackleEdit(this.name, this.type, {this.archive = false});

  final String name;
  final T type;

  /// The person chose to archive the item instead of saving it.
  final bool archive;
}

/// Name and type of a bait or piece of gear, to add or to edit. When
/// editing ([onArchiveLabel] given) it also offers to archive the item.
class TackleDialog<T> extends StatefulWidget {
  const TackleDialog({
    super.key,
    required this.title,
    required this.types,
    required this.typeLabel,
    required this.initialType,
    this.initialName = '',
    this.archiveLabel,
  });

  final String title;
  final List<T> types;
  final String Function(T) typeLabel;
  final T initialType;
  final String initialName;

  /// Shown as a third action when editing.
  final String? archiveLabel;

  @override
  State<TackleDialog<T>> createState() => _TackleDialogState<T>();
}

class _TackleDialogState<T> extends State<TackleDialog<T>> {
  late final _name = TextEditingController(text: widget.initialName);
  late T _type = widget.initialType;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.tackleName),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in widget.types)
                  ChoiceChip(
                    label: Text(widget.typeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.archiveLabel != null)
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(TackleEdit<T>(_name.text.trim(), _type, archive: true)),
            child: Text(widget.archiveLabel!),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(TackleEdit<T>(_name.text.trim(), _type)),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
