import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/media/photo_storage.dart';
import '../theme/tokens.dart';

/// Square photo from the app's photo folder, or a quiet placeholder.
class PhotoThumb extends ConsumerWidget {
  const PhotoThumb({
    super.key,
    required this.relativePath,
    this.size = 64,
    this.radius = PiscatioRadii.thumb,
    this.placeholderIcon = Icons.phishing_outlined,
  });

  final String? relativePath;
  final double size;
  final double radius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final root = ref.watch(photoRootProvider).value;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(
        child: Icon(
          placeholderIcon,
          size: size * 0.42,
          color: context.palette.muted,
        ),
      ),
    );
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: relativePath == null || root == null
            ? placeholder
            : Image.file(
                resolvePhoto(root, relativePath!),
                fit: BoxFit.cover,
                cacheWidth: pixels,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
