import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
  final _pinFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameController = TextEditingController();
  final _pinControllers = List.generate(4, (_) => TextEditingController());
  final _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String get _pin =>
      _pinControllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    _pinFieldKey.currentState?.didChange(_pin);

    if (value.isNotEmpty && index < _pinFocusNodes.length - 1) {
      _pinFocusNodes[index + 1].requestFocus();
    }
  }

  void _submit() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      await ref
          .read(authNotifierProvider.notifier)
          .loginAnonymously(
            name: _nameController.text.trim(),
            pin: _pin,
            eventId: widget.eventId,
          );

      if (mounted && ref.read(authNotifierProvider) is AuthAuthenticated) {
        Navigator.of(context).pop();
      }
    }
  }

  String _getErrorMessage(AuthFailureReason reason, AppLocalizations i18n) {
    switch (reason) {
      case AuthFailureReason.invalidPin:
        return i18n.loginErrorInvalidPin;
      case AuthFailureReason.invalidCredentials:
        return i18n.loginErrorInvalidCredentials;
      case AuthFailureReason.eventNotFound:
        return i18n.loginErrorEventNotFound;
      case AuthFailureReason.eventUnavailable:
        return i18n.loginErrorEventUnavailable;
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    i18n.pinLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                      if (trimmed.length > 80) return i18n.nameMaxLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  FormField<String>(
                    key: _pinFieldKey,
                    validator: (_) {
                      if (_pin.isEmpty) return i18n.pinRequired;
                      if (!RegExp(r'^\d{4}$').hasMatch(_pin)) {
                        return i18n.pinInvalidFormat;
                      }
                      return null;
                    },
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: List.generate(4, (index) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 3 ? 0 : AppSpacing.sm,
                                ),
                                child: TextField(
                                  key: Key('anonymous_pin_digit_$index'),
                                  controller: _pinControllers[index],
                                  focusNode: _pinFocusNodes[index],
                                  enabled: !isLoading,
                                  autofocus: index == 0,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    errorText: null,
                                  ),
                                  onChanged: (value) =>
                                      _onPinChanged(index, value),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (field.hasError) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            field.errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    key: const Key('anonymous_pin_info_card'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i18n.pinRecoveryTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                i18n.pinRecoveryMessage,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
