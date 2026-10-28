import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/registration_rules.dart';
import '../controllers/password_recovery_providers.dart';
import '../controllers/password_recovery_state.dart';
import '../screens/reset_password_screen.dart';

class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _requestedEmail;

  bool get _isFormValid =>
      isValidRegistrationEmail(_emailController.text.trim());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isFormValid || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();
    await ref
        .read(passwordRecoveryNotifierProvider.notifier)
        .requestPasswordReset(email: email);

    if (!mounted) return;

    final state = ref.read(passwordRecoveryNotifierProvider);
    if (state is PasswordRecoverySuccess &&
        state.operation == PasswordRecoveryOperation.request) {
      setState(() => _requestedEmail = email);
    }
  }

  String _getErrorMessage(
    PasswordRecoveryFailureReason reason,
    AppLocalizations i18n,
  ) {
    return switch (reason) {
      PasswordRecoveryFailureReason.networkError =>
        i18n.forgotPasswordNetworkError,
      _ => i18n.forgotPasswordGenericError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(passwordRecoveryNotifierProvider);
    final isLoading =
        state is PasswordRecoveryLoading &&
        state.operation == PasswordRecoveryOperation.request;
    final isSuccess =
        state is PasswordRecoverySuccess &&
        state.operation == PasswordRecoveryOperation.request;
    final hasCodeForCurrentEmail =
        isSuccess && _requestedEmail == _emailController.text.trim();
    final error =
        state is PasswordRecoveryError &&
            state.operation == PasswordRecoveryOperation.request
        ? state
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                Container(
                  key: const Key('forgot_password_error_banner'),
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
                          _getErrorMessage(error.reason, i18n),
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
              if (hasCodeForCurrentEmail) ...[
                Container(
                  key: const Key('forgot_password_success_message'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    i18n.forgotPasswordSuccessMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                key: const Key('forgot_password_email_input'),
                controller: _emailController,
                enabled: !isLoading,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) =>
                    _isFormValid && !isLoading ? _submit() : null,
                decoration: InputDecoration(
                  hintText: i18n.registrationEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) =>
                    isValidRegistrationEmail(value?.trim() ?? '')
                    ? null
                    : i18n.registrationEmailInvalid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                key: const Key('forgot_password_submit_button'),
                onPressed: isLoading || !_isFormValid ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasCodeForCurrentEmail
                            ? i18n.forgotPasswordResendButton
                            : i18n.forgotPasswordSubmitButton,
                      ),
              ),
              if (hasCodeForCurrentEmail) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  key: const Key('forgot_password_have_code_button'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ResetPasswordScreen(email: _requestedEmail!),
                    ),
                  ),
                  child: Text(i18n.forgotPasswordHaveCode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
