import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/event_creation_state.dart';
import '../controllers/event_draft_providers.dart';
import '../widgets/event_wizard_step_header.dart';
import '../widgets/existing_group_section.dart';
import '../widgets/group_mode_accordion_tile.dart';
import '../widgets/new_group_section.dart';
import 'create_event_success_screen.dart';

class CreateEventStep2Screen extends ConsumerStatefulWidget {
  const CreateEventStep2Screen({super.key});

  @override
  ConsumerState<CreateEventStep2Screen> createState() =>
      _CreateEventStep2ScreenState();
}

class _CreateEventStep2ScreenState
    extends ConsumerState<CreateEventStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _newGroupNameController;
  late final TextEditingController _memberIdentifierController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(eventDraftProvider);
    _newGroupNameController = TextEditingController(
      text: draft.newGroupName ?? '',
    );
    _memberIdentifierController = TextEditingController();
  }

  @override
  void dispose() {
    _newGroupNameController.dispose();
    _memberIdentifierController.dispose();
    super.dispose();
  }

  void _addMember() {
    final text = _memberIdentifierController.text.trim();
    if (text.isEmpty) return;

    final draft = ref.read(eventDraftProvider);
    if (draft.newGroupMembers.contains(text)) {
      final i18n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(i18n.memberAlreadyAdded),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(eventDraftProvider.notifier).addMember(text);
    _memberIdentifierController.clear();
  }

  void _onSubmit() {
    final draft = ref.read(eventDraftProvider);

    if (draft.isNewGroup) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
      ref
          .read(eventDraftProvider.notifier)
          .setNewGroupName(_newGroupNameController.text);
    } else {
      if (draft.selectedGroupId == null ||
          draft.selectedGroupId!.trim().isEmpty) {
        final i18n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(i18n.selectGroupRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();
    final updatedDraft = ref.read(eventDraftProvider);
    ref.read(createEventNotifierProvider.notifier).createEvent(updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final creationState = ref.watch(createEventNotifierProvider);
    final draft = ref.watch(eventDraftProvider);
    final isLoading = creationState is EventCreationLoading;

    // Vista de éxito / resumen del evento creado
    if (creationState is EventCreationSuccess) {
      return CreateEventSuccessScreen(event: creationState.event);
    }

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
          onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EventWizardStepHeader(
                  stepBadge: i18n.step2Badge,
                  progress: 1.0,
                  title: i18n.step2Title,
                  subtitle: i18n.step2Subtitle,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Banner de error si falló la creación
                if (creationState is EventCreationError) ...[
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
                            i18n.createEventErrorGeneric,
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

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Selector de modo expandible (Acordeón de selección)
                      Column(
                        key: const Key('group_mode_selector'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Opción 1: Grupo existente
                          GroupModeAccordionTile(
                            isSelected: !draft.isNewGroup,
                            title: i18n.existingGroupOption,
                            subtitle: i18n.existingGroupSubtitle,
                            onTap: isLoading
                                ? () {}
                                : () => ref
                                      .read(eventDraftProvider.notifier)
                                      .setIsNewGroup(false),
                            child: const ExistingGroupSection(),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Opción 2: Crear grupo nuevo
                          GroupModeAccordionTile(
                            isSelected: draft.isNewGroup,
                            title: i18n.newGroupOption,
                            subtitle: i18n.newGroupSubtitle,
                            onTap: isLoading
                                ? () {}
                                : () => ref
                                      .read(eventDraftProvider.notifier)
                                      .setIsNewGroup(true),
                            child: NewGroupSection(
                              groupNameController: _newGroupNameController,
                              memberIdentifierController:
                                  _memberIdentifierController,
                              onAddMember: _addMember,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Botones de acción (Atrás y Crear Evento)
                      Row(
                        children: [
                          OutlinedButton.icon(
                            key: const Key('wizard_step2_back_button'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(100, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(i18n.backButton),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('create_event_submit_button'),
                              onPressed: isLoading ? null : _onSubmit,
                              icon: isLoading
                                  ? null
                                  : const Icon(Icons.check_rounded),
                              label: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(i18n.createEventSubmitButton),
                            ),
                          ),
                        ],
                      ),
                    ],
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
