import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Quiet sentence-case heading for groups of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        28,
        PiscatioSizes.gutter,
        8,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall!
              .copyWith(color: context.palette.muted),
        ),
      ),
    );
  }
}
