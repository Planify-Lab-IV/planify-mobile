import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_state.dart';

class AnonymousLoginDialog extends ConsumerStatefulWidget {
  final String? eventId;

  const AnonymousLoginDialog({super.key, this.eventId});

  @override
  ConsumerState<AnonymousLoginDialog> createState() =>
      _AnonymousLoginDialogState();
}

class _AnonymousLoginDialogState extends ConsumerState<AnonymousLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authNotifierProvider.notifier).clearError();

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      ref
          .read(authNotifierProvider.notifier)
          .loginAnonymously(
            name: _nameController.text,
            pin: _pinController.text,
            eventId: widget.eventId,
          );
    }
  }

  String _getErrorMessage(AuthFailureReason reason, AppLocalizations i18n) {
    switch (reason) {
      case AuthFailureReason.invalidPin:
        return i18n.loginErrorInvalidPin;
      case AuthFailureReason.invalidCredentials:
        return i18n.loginErrorInvalidCredentials;
      case AuthFailureReason.networkError:
      case AuthFailureReason.unknown:
        return i18n.loginErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícono y Título
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    i18n.continueAsGuest,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Badge de Evento si existe
                  if (widget.eventId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${i18n.eventIdLabel}: ${widget.eventId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Banner de Error
                  if (authState is AuthError) ...[
                    Container(
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
                              _getErrorMessage(authState.reason, i18n),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Campo Nombre
                  TextFormField(
                    key: const Key('anonymous_name_input'),
                    controller: _nameController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: i18n.nameLabel,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return i18n.nameRequired;
                      if (trimmed.length < 2) return i18n.nameMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Campo PIN
                  TextFormField(
                    key: const Key('anonymous_pin_input'),
                    controller: _pinController,
                    enabled: !isLoading,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: i18n.pinLabel,
                      prefixIcon: const Icon(Icons.dialpad_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return i18n.pinRequired;
                      if (trimmed.length < 4) return i18n.pinMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Acciones
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          key: const Key('anonymous_cancel_button'),
                          onPressed: isLoading
                              ? null
                              : () {
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .clearError();
                                  Navigator.of(context).pop();
                                },
                          child: Text(i18n.cancelButton),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('anonymous_submit_button'),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(i18n.joinButton),
                        ),
                      ),
                    ],
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
