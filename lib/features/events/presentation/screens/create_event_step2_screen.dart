import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../groups/presentation/controllers/groups_providers.dart';
import '../controllers/event_creation_state.dart';
import '../controllers/event_draft_providers.dart';
import '../widgets/event_wizard_step_header.dart';

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
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final isLoading = creationState is EventCreationLoading;

    // Vista de éxito
    if (creationState is EventCreationSuccess) {
      return _buildSuccessView(context, creationState.event);
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
      body: Center(
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

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Selector de modo: Grupo existente vs Crear grupo nuevo
                          SegmentedButton<bool>(
                            key: const Key('group_mode_selector'),
                            segments: [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(i18n.existingGroupOption),
                                icon: const Icon(Icons.groups_outlined),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(i18n.newGroupOption),
                                icon: const Icon(Icons.group_add_outlined),
                              ),
                            ],
                            selected: {draft.isNewGroup},
                            onSelectionChanged: isLoading
                                ? null
                                : (newSelection) {
                                    ref
                                        .read(eventDraftProvider.notifier)
                                        .setIsNewGroup(newSelection.first);
                                  },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Contenido según el modo seleccionado
                          if (!draft.isNewGroup)
                            _buildExistingGroupSection(context, myGroupsAsync)
                          else
                            _buildNewGroupSection(context, draft),

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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingGroupSection(
    BuildContext context,
    AsyncValue<List<dynamic>> myGroupsAsync,
  ) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = ref.watch(eventDraftProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          i18n.selectGroupLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        myGroupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  i18n.noGroupsAvailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              );
            }

            final groupIds = groups.map((g) => g.id as String).toSet();
            final validSelectedGroupId =
                groupIds.contains(draft.selectedGroupId)
                ? draft.selectedGroupId
                : null;

            return DropdownButtonFormField<String>(
              key: const Key('select_group_dropdown'),
              initialValue: validSelectedGroupId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: i18n.selectGroupHint,
                prefixIcon: const Icon(
                  Icons.group_outlined,
                  color: AppColors.primary,
                ),
              ),
              items: groups.map((group) {
                return DropdownMenuItem<String>(
                  value: group.id as String,
                  child: Text(
                    '${group.name} (${group.memberCount})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (selectedId) {
                if (selectedId != null) {
                  final group = groups.firstWhere((g) => g.id == selectedId);
                  ref
                      .read(eventDraftProvider.notifier)
                      .setSelectedGroup(
                        groupId: group.id as String,
                        groupName: group.name as String,
                      );
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return i18n.selectGroupRequired;
                }
                return null;
              },
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  i18n.loadingGroups,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                    i18n.errorLoadingGroups,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.refresh(myGroupsProvider),
                  child: Text(i18n.retryButton),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewGroupSection(BuildContext context, dynamic draft) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final members = (draft.newGroupMembers as List<String>);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre del nuevo grupo
        Text(
          i18n.newGroupNameLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          key: const Key('new_group_name_input'),
          controller: _newGroupNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: i18n.newGroupNameHint,
            prefixIcon: const Icon(
              Icons.group_outlined,
              color: AppColors.primary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return i18n.newGroupNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Entrada de identificadores de miembros
        Text(
          i18n.memberIdentifierLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('member_identifier_input'),
                controller: _memberIdentifierController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addMember(),
                decoration: InputDecoration(
                  hintText: i18n.memberIdentifierHint,
                  prefixIcon: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key('add_member_button'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                minimumSize: const Size(52, 52),
              ),
              onPressed: _addMember,
              icon: const Icon(Icons.add_rounded),
              tooltip: i18n.addMemberButton,
            ),
          ],
        ),

        // Lista de chips de miembros agregados
        if (members.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            i18n.membersListTitle(members.length),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: members.map((member) {
              return Chip(
                key: Key('member_chip_$member'),
                avatar: const CircleAvatar(
                  backgroundColor: AppColors.lightBlue,
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.darkBlue,
                  ),
                ),
                label: Text(
                  member,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  ref.read(eventDraftProvider.notifier).removeMember(member);
                },
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, dynamic event) {
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
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 44,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      i18n.createEventSuccessTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      i18n.createEventSuccessSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(color: AppColors.outline),
                    const SizedBox(height: AppSpacing.md),

                    // Resumen del evento creado
                    _buildSummaryTile(
                      context,
                      label: i18n.createdEventIdLabel,
                      value: event.id as String,
                      valueKey: const Key('created_event_id'),
                      icon: Icons.tag_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSummaryTile(
                      context,
                      label: i18n.eventNameLabel,
                      value: event.name as String,
                      valueKey: const Key('created_event_name'),
                      icon: Icons.celebration_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSummaryTile(
                      context,
                      label: i18n.eventLocationLabel,
                      value: event.location as String,
                      valueKey: const Key('created_event_location'),
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSummaryTile(
                      context,
                      label: i18n.assignedGroupLabel,
                      value: event.groupName as String,
                      valueKey: const Key('created_event_group'),
                      icon: Icons.groups_outlined,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Botón para volver al inicio
                    ElevatedButton.icon(
                      key: const Key('back_to_home_button'),
                      onPressed: () {
                        ref.read(eventDraftProvider.notifier).reset();
                        ref
                            .read(createEventNotifierProvider.notifier)
                            .resetState();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: Text(i18n.backToHomeButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
    BuildContext context, {
    required String label,
    required String value,
    required Key valueKey,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
