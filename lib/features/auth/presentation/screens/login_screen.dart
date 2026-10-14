import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planify/core/widgets/planify_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../invitations/presentation/controllers/invitation_providers.dart';
import '../../../invitations/presentation/controllers/invitation_state.dart';
import '../widgets/login_form.dart';

// que sea un ConsumerStatefulWidget le permite tener estado local, como el texto que vas escribiendo
// en los campos y si la contraseña esta oculta o visible con el ojito
class LoginScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const LoginScreen({super.key, this.eventId});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _getInvitationErrorMessage(
    InvitationErrorReason reason,
    AppLocalizations i18n,
  ) {
    switch (reason) {
      case InvitationErrorReason.invalidFormat:
        return i18n.invitationErrorInvalid;
      case InvitationErrorReason.notFound:
        return i18n.invitationErrorNotFound;
      case InvitationErrorReason.expired:
        return i18n.invitationErrorExpired;
      case InvitationErrorReason.network:
        return i18n.invitationErrorNetwork;
      case InvitationErrorReason.unknown:
        return i18n.invitationErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context)!;
    final invitationState = ref.watch(invitationNotifierProvider);

    return Scaffold(
      body: SafeArea(
        // evita que el contenido se superponga con el notch de la cámara o la barra de batería del teléfono.
        child: Center(
          child: SingleChildScrollView(
            // si el teclado se superpone con el forms, se hace scroll para ver el forms
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const PlanifyLogo(),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Planify',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    i18n.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Banner de error controlado de invitación si ocurrió
                  if (invitationState is InvitationError) ...[
                    Container(
                      key: const Key('invitation_error_banner'),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _getInvitationErrorMessage(
                                invitationState.reason,
                                i18n,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('dismiss_invitation_error_button'),
                            icon: const Icon(Icons.close, size: 18),
                            color: theme.colorScheme.onErrorContainer,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref
                                .read(invitationNotifierProvider.notifier)
                                .clearInvitation(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Badge de Evento si el usuario llegó por invitación
                  if (widget.eventId != null) ...[
                    Container(
                      key: const Key('invitation_event_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              i18n.invitationBannerEvent,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // cuando llamo a widget estoy accediendo a las variables que tiene
                  // guardadas el login screen
                  LoginForm(eventId: widget.eventId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
