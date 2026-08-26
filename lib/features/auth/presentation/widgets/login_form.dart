import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_state.dart';
import 'anonymous_login_dialog.dart';

class LoginForm extends ConsumerStatefulWidget {
  final String? eventId;

  const LoginForm({super.key, this.eventId});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>(); // valida la informacion del forms
  final _identifierController =
      TextEditingController(); // guarda en tiempo real lo que el usuario escribe en el input
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Limpia errores previos al reintentar
    ref.read(authNotifierProvider.notifier).clearError();

    if (_formKey.currentState?.validate() ?? false) {
      // Cierra el teclado
      FocusScope.of(context).unfocus();

      ref
          .read(authNotifierProvider.notifier)
          .login(
            identifier: _identifierController.text,
            password: _passwordController.text,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Input: Correo o Usuario
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                key: const Key('identifier_input'),
                controller: _identifierController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: i18n.identifierLabel,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return i18n.identifierRequired;
                  if (trimmed.contains('@') && !trimmed.contains('.')) {
                    return i18n.identifierInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Input: Contraseña
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                key: const Key('password_input'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: i18n.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return i18n.passwordRequired;
                  if (trimmed.length < 6) return i18n.passwordMinLength;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botón Iniciar Sesión
              ElevatedButton(
                key: const Key('login_submit_button'),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(i18n.loginButton),
              ),
              const SizedBox(height: AppSpacing.md),

              // Separador "o"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      i18n.orDivider,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Botón Continuar como Invitado
              OutlinedButton(
                key: const Key('guest_login_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(authNotifierProvider.notifier).clearError();
                        showDialog<void>(
                          context: context,
                          barrierDismissible: !isLoading,
                          builder: (dialogContext) => AnonymousLoginDialog(
                            eventId: widget.eventId,
                          ),
                        );
                      },
                child: Text(i18n.continueAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
