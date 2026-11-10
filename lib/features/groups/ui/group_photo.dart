import 'package:flutter/material.dart';

import '../../../core/images.dart';

/// Round group photo (SPEC 18); the house icon when the group has none or while the
/// photo loads.
class GroupPhoto extends StatelessWidget {
  const GroupPhoto({super.key, required this.photoPath, this.radius = 20});

  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Icon(Icons.home_rounded, size: radius, color: scheme.onPrimaryContainer),
    );
    final path = photoPath;
    if (path == null) return placeholder;
    return ClipOval(
      child: StorageImage(path: path, width: radius * 2, height: radius * 2, fallback: placeholder),
    );
  }
}
