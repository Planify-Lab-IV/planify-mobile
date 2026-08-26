import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/event_draft_providers.dart';
import '../widgets/event_wizard_step_header.dart';
import 'create_event_step2_screen.dart';

class CreateEventStep1Screen extends ConsumerStatefulWidget {
  const CreateEventStep1Screen({super.key});

  @override
  ConsumerState<CreateEventStep1Screen> createState() =>
      _CreateEventStep1ScreenState();
}

class _CreateEventStep1ScreenState
    extends ConsumerState<CreateEventStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final currentDraft = ref.read(eventDraftProvider);
    _nameController = TextEditingController(text: currentDraft.name);
    _locationController = TextEditingController(text: currentDraft.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      // Guardamos los datos en el estado central del borrador
      ref
          .read(eventDraftProvider.notifier)
          .updateBasicInfo(
            name: _nameController.text,
            location: _locationController.text,
          );

      // Avanzamos al Paso 2
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const CreateEventStep2Screen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.createEventTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EventWizardStepHeader(
                  stepBadge: i18n.step1Badge,
                  progress: 0.5,
                  title: i18n.step1Title,
                  subtitle: i18n.step1Subtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Campo: Nombre del evento
                          Text(
                            i18n.eventNameLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            key: const Key('event_name_input'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: i18n.eventNameHint,
                              prefixIcon: const Icon(
                                Icons.celebration_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return i18n.eventNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Campo: Lugar del evento (lugarTexto)
                          Text(
                            i18n.eventLocationLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            key: const Key('event_location_input'),
                            controller: _locationController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onContinue(),
                            decoration: InputDecoration(
                              hintText: i18n.eventLocationHint,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return i18n.eventLocationRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Botón Continuar al siguiente paso
                          ElevatedButton.icon(
                            key: const Key('wizard_continue_button'),
                            onPressed: _onContinue,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(i18n.continueButton),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
