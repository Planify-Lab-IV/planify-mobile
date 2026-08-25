import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planify/core/widgets/planify_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/login_form.dart';

// que sea un ConsumerStatefulWidget le permite tener estado local, como el texto que vas escribiendo
// en los campos y si la contraseña esta oculta o visible con el ojito
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'organiza tus planes, sin vueltas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
