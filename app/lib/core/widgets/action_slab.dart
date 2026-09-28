import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The big bottom action ("Start trip", "+ Catch"): full width, 76 dp tall,
/// sits in the thumb zone. Usable with a wet hand in bright sun.
class ActionSlab extends StatelessWidget {
  const ActionSlab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = background ?? scheme.primary;
    final fg = foreground ?? scheme.onPrimary;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? bg : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(PiscatioRadii.slab),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PiscatioSizes.actionSlab,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 30, color: fg),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: PiscatioFonts.expanded,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.1,
                        color: enabled ? fg : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
