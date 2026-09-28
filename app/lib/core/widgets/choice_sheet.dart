import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class Choice<T> {
  const Choice(this.value, this.label, {this.description});

  final T value;
  final String label;
  final String? description;
}

/// Bottom sheet listing options; returns the chosen value (or null if
/// dismissed). The current value is marked and announced as selected.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<Choice<T>> choices,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
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
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            for (final c in choices)
              ChoiceRow(
                label: c.label,
                description: c.description,
                selected: c.value == selected,
                onTap: () => Navigator.of(context).pop(c.value),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A tall selectable row with a check mark when selected.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiscatioSizes.gutter,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.check_rounded,
                    size: 28,
                    color: context.palette.accentText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
