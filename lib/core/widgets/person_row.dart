import 'package:flutter/material.dart';

import '../../features/friends/domain/person.dart';
import '../theme/app_spacing.dart';
import 'initials_avatar.dart';

/// Fila reutilizable para representar a una persona con su avatar de iniciales,
/// nombre completo, identificador de usuario (@username) y una acción opcional.
///
/// Mantiene la presentación independiente de las reglas de amistad para permitir
/// su reutilización tanto en la pantalla de Amigos como en futuros selectores.
class PersonRow extends StatelessWidget {
  final Person person;
  final Widget? trailing;
  final ImageProvider<Object>? imageProvider;
  final EdgeInsetsGeometry contentPadding;
  final double avatarRadius;
  final VoidCallback? onTap;

  const PersonRow({
    super.key,
    required this.person,
    this.trailing,
    this.imageProvider,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.avatarRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedUsername = person.username.startsWith('@')
        ? person.username
        : '@${person.username}';

    final content = Padding(
      padding: contentPadding,
      child: Row(
        children: [
          InitialsAvatar(
            name: person.name,
            imageProvider: imageProvider,
            radius: avatarRadius,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedUsername,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }

    return content;
  }
}
