import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/registration_rules.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_state.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool get _isFormValid =>
      isValidRegistrationName(_nameController.text.trim()) &&
      isValidRegistrationUsername(_usernameController.text.trim()) &&
      isValidRegistrationEmail(_emailController.text.trim()) &&
      isValidRegistrationPassword(_passwordController.text);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (!_isFormValid || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted && ref.read(authNotifierProvider) is AuthAuthenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  bool _isRegistrationError(AuthFailureReason reason) {
    return switch (reason) {
      AuthFailureReason.registrationConflict ||
      AuthFailureReason.invalidRegistrationData ||
      AuthFailureReason.networkError ||
      AuthFailureReason.unknown => true,
      _ => false,
    };
  }

  String _getErrorMessage(AuthFailureReason reason, AppLocalizations i18n) {
    return switch (reason) {
      AuthFailureReason.registrationConflict => i18n.registrationErrorConflict,
      AuthFailureReason.invalidRegistrationData =>
        i18n.registrationErrorInvalidData,
      AuthFailureReason.networkError => i18n.registrationErrorNetwork,
      _ => i18n.registrationErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

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
              Text(
                i18n.registrationTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (authState is AuthError &&
                  _isRegistrationError(authState.reason)) ...[
                Container(
                  key: const Key('register_error_banner'),
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
              TextFormField(
                key: const Key('registration_name_input'),
                controller: _nameController,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: i18n.registrationNameLabel,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    isValidRegistrationName(value?.trim() ?? '')
                    ? null
                    : i18n.registrationNameInvalid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registration_username_input'),
                controller: _usernameController,
                enabled: !isLoading,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: i18n.registrationUsernameLabel,
                  helperText: i18n.registrationUsernameHelp,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) =>
                    isValidRegistrationUsername(value?.trim() ?? '')
                    ? null
                    : i18n.registrationUsernameInvalid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registration_email_input'),
                controller: _emailController,
                enabled: !isLoading,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registration_password_input'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) =>
                    _isFormValid && !isLoading ? _submit() : null,
                decoration: InputDecoration(
                  hintText: i18n.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                  ),
                ),
                validator: (value) => isValidRegistrationPassword(value ?? '')
                    ? null
                    : i18n.registrationPasswordInvalid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                key: const Key('register_submit_button'),
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
                    : Text(i18n.registrationSubmitButton),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('back_to_login_button'),
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(i18n.registrationBackToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
