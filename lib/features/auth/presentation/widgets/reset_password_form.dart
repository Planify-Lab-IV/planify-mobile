import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/registration_rules.dart';
import '../controllers/password_recovery_providers.dart';
import '../controllers/password_recovery_state.dart';

class ResetPasswordForm extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordForm({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<ResetPasswordForm> {
  static const _codeLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  bool _obscurePassword = true;

  String get _code =>
      _codeControllers.map((controller) => controller.text).join();

  bool get _isFormValid =>
      _code.length == _codeLength &&
      isValidRegistrationPassword(_passwordController.text);

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(
      _codeLength,
      (_) => TextEditingController(),
    );
    _codeFocusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isFormValid || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    await ref
        .read(passwordRecoveryNotifierProvider.notifier)
        .resetPassword(
          email: widget.email,
          code: _code,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;

    final state = ref.read(passwordRecoveryNotifierProvider);
    if (state is PasswordRecoveryError &&
        state.operation == PasswordRecoveryOperation.reset &&
        state.reason == PasswordRecoveryFailureReason.invalidResetCode) {
      for (final controller in _codeControllers) {
        controller.clear();
      }
      _codeFocusNodes.first.requestFocus();
      setState(() {});
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.substring(0, _codeLength - index);
      for (var offset = 0; offset < digits.length; offset++) {
        _codeControllers[index + offset].value = TextEditingValue(
          text: digits[offset],
          selection: const TextSelection.collapsed(offset: 1),
        );
      }

      final lastFilledIndex = index + digits.length - 1;
      if (lastFilledIndex == _codeLength - 1) {
        _passwordFocusNode.requestFocus();
      } else {
        _codeFocusNodes[lastFilledIndex + 1].requestFocus();
      }

      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index == _codeLength - 1) {
        _passwordFocusNode.requestFocus();
      } else {
        _codeFocusNodes[index + 1].requestFocus();
      }
    } else if (index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  String _getErrorMessage(
    PasswordRecoveryFailureReason reason,
    AppLocalizations i18n,
  ) {
    return switch (reason) {
      PasswordRecoveryFailureReason.invalidResetCode =>
        i18n.resetPasswordInvalidCodeError,
      PasswordRecoveryFailureReason.networkError =>
        i18n.resetPasswordNetworkError,
      _ => i18n.resetPasswordGenericError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(passwordRecoveryNotifierProvider);
    final isLoading =
        state is PasswordRecoveryLoading &&
        state.operation == PasswordRecoveryOperation.reset;
    final isSuccess =
        state is PasswordRecoverySuccess &&
        state.operation == PasswordRecoveryOperation.reset;
    final error =
        state is PasswordRecoveryError &&
            state.operation == PasswordRecoveryOperation.reset
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
              TextFormField(
                key: const Key('reset_password_email_input'),
                initialValue: widget.email,
                readOnly: true,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: i18n.registrationEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                i18n.resetPasswordCodeLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(_codeLength, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == _codeLength - 1 ? 0 : AppSpacing.xs,
                      ),
                      child: Focus(
                        onKeyEvent: (_, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.backspace &&
                              _codeControllers[index].text.isEmpty &&
                              index > 0) {
                            _codeFocusNodes[index - 1].requestFocus();
                            return KeyEventResult.handled;
                          }

                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          key: Key('reset_password_code_digit_$index'),
                          controller: _codeControllers[index],
                          focusNode: _codeFocusNodes[index],
                          enabled: !isLoading,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          onChanged: (value) => _onCodeChanged(index, value),
                          onEditingComplete: index == _codeLength - 1
                              ? _passwordFocusNode.requestFocus
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('reset_password_new_password_input'),
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) =>
                    _isFormValid && !isLoading ? _submit() : null,
                decoration: InputDecoration(
                  hintText: i18n.resetPasswordNewPasswordLabel,
                  helperText: i18n.resetPasswordNewPasswordHelp,
                  helperMaxLines: 2,
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
              const SizedBox(height: AppSpacing.lg),
              if (error != null) ...[
                Container(
                  key: const Key('reset_password_error_banner'),
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
                if (error.reason ==
                    PasswordRecoveryFailureReason.invalidResetCode)
                  TextButton(
                    key: const Key('reset_password_request_new_code_button'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(i18n.resetPasswordRequestNewCode),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (isSuccess) ...[
                Container(
                  key: const Key('reset_password_success_message'),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    i18n.resetPasswordSuccessMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  key: const Key('reset_password_back_to_login_button'),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(i18n.resetPasswordBackToLogin),
                ),
              ],
              ElevatedButton(
                key: const Key('reset_password_submit_button'),
                onPressed: isLoading || !_isFormValid || isSuccess
                    ? null
                    : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(i18n.resetPasswordSubmitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
