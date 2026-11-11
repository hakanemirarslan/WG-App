import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images.dart';
import '../../../core/widgets.dart';
import '../providers/profile_providers.dart';

/// Round avatar of a person: their profile photo (SPEC 18) when they have one and I
/// may see it, else the first letter of their name ([InitialAvatar]). The photo path
/// comes from [avatarPathsProvider]; [photoPath] overrides it (own profile in the
/// settings, so a just-changed photo shows at once).
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 18,
    this.photoPath,
  });

  final String userId;
  final String name;
  final double radius;
  final String? photoPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = photoPath ?? ref.watch(avatarPathsProvider).value?[userId];
    final initial = InitialAvatar(name: name, radius: radius);
    if (path == null) return initial;
    return ClipOval(
      child: StorageImage(path: path, width: radius * 2, height: radius * 2, fallback: initial),
    );
  }
}
