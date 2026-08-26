import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../events/presentation/controllers/event_draft_providers.dart';
import '../../../events/presentation/screens/create_event_step1_screen.dart';

class OrganizerHomeScreen extends ConsumerWidget {
  final OrganizerSession session;

  const OrganizerHomeScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoggingOut = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.organizerPanelTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: i18n.logoutButton,
            icon: const Icon(Icons.logout_rounded),
            onPressed: isLoggingOut
                ? null
                : () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      i18n.welcomeOrganizer(session.name),
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      i18n.sessionActiveDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(color: AppColors.outline),
                    const SizedBox(height: AppSpacing.md),

                    // Información de sesión
                    _buildInfoRow(
                      context,
                      label: i18n.emailLabel,
                      value: session.email,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      label: i18n.roleLabel,
                      value: i18n.organizerRole,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Botón Crear Evento
                    ElevatedButton.icon(
                      key: const Key('create_event_button'),
                      onPressed: () {
                        ref.read(eventDraftProvider.notifier).reset();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const CreateEventStep1Screen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(i18n.createEventButton),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Botón de Cerrar Sesión
                    OutlinedButton.icon(
                      key: const Key('logout_button'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: isLoggingOut
                          ? null
                          : () => ref
                                .read(authNotifierProvider.notifier)
                                .logout(),
                      icon: isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(i18n.logoutButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
