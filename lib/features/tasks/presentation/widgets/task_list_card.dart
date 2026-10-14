import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../../domain/task.dart';
import '../../domain/task_action.dart';
import '../../domain/task_status.dart';
import '../controllers/tasks_context.dart';
import '../controllers/tasks_notifier.dart';
import '../controllers/tasks_providers.dart';
import 'reassign_task_dialog.dart';

class TaskListCard extends ConsumerWidget {
  final List<EventParticipant> participants;
  final TasksContext tasksContext;

  const TaskListCard({
    super.key,
    required this.participants,
    required this.tasksContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(tasksNotifierProvider(tasksContext));
    final notifier = ref.read(tasksNotifierProvider(tasksContext).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.tasksSectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.hasLoadError)
          _TasksLoadError(onRetry: notifier.load)
        else if (state.tasks.isEmpty)
          _TasksEmptyCard(message: i18n.noTasksPlaceholder)
        else
          Card(
            key: const Key('tasks_list_card'),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < state.tasks.length; index++) ...[
                  _TaskRow(
                    task: state.tasks[index],
                    participantName: _participantNameFor(state.tasks[index]),
                    action: notifier.actionFor(state.tasks[index]),
                    isProcessing:
                        state.isOperating &&
                        state.activeTaskId == state.tasks[index].id,
                    onClaim: () =>
                        _claim(context, notifier, state.tasks[index]),
                    onComplete: () =>
                        _complete(context, notifier, state.tasks[index]),
                    onReassign: () =>
                        _reassign(context, notifier, state.tasks[index]),
                  ),
                  if (index != state.tasks.length - 1)
                    const Divider(height: 1, indent: AppSpacing.md),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String? _participantNameFor(Task task) {
    final participantId = task.assignedToParticipantId;
    if (participantId == null) return null;

    for (final participant in participants) {
      if (participant.id == participantId) return participant.username;
    }
    return null;
  }

  Future<void> _claim(
    BuildContext context,
    TasksNotifier notifier,
    Task task,
  ) async {
    final claimed = await notifier.claim(task.id);
    if (!context.mounted || claimed) return;
    _showOperationError(context);
  }

  Future<void> _complete(
    BuildContext context,
    TasksNotifier notifier,
    Task task,
  ) async {
    final completed = await notifier.complete(task.id);
    if (!context.mounted || completed) return;
    _showOperationError(context);
  }

  Future<void> _reassign(
    BuildContext context,
    TasksNotifier notifier,
    Task task,
  ) {
    return ReassignTaskDialog.show(
      context,
      participants: participants,
      onAssign: (participantId) => notifier.assign(task.id, participantId),
    );
  }

  void _showOperationError(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(i18n.tasksOperationError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
  }
}

class _TasksEmptyCard extends StatelessWidget {
  final String message;

  const _TasksEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('tasks_empty_card'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TasksLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TasksLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      key: const Key('tasks_load_error_card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                i18n.tasksLoadError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(i18n.retryButton)),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final String? participantName;
  final TaskAction? action;
  final bool isProcessing;
  final Future<void> Function() onClaim;
  final Future<void> Function() onComplete;
  final Future<void> Function() onReassign;

  const _TaskRow({
    required this.task,
    required this.participantName,
    required this.action,
    required this.isProcessing,
    required this.onClaim,
    required this.onComplete,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = _taskStatusPresentation(i18n, task.status);

    return Padding(
      key: Key('task_row_${task.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: status.color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TaskStatusChip(label: status.label, color: status.color),
                    if (participantName != null)
                      Text(
                        i18n.taskAssignedTo(participantName!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _TaskActionButton(
                    action: action!,
                    taskId: task.id,
                    isProcessing: isProcessing,
                    onClaim: onClaim,
                    onComplete: onComplete,
                    onReassign: onReassign,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  final TaskAction action;
  final String taskId;
  final bool isProcessing;
  final Future<void> Function() onClaim;
  final Future<void> Function() onComplete;
  final Future<void> Function() onReassign;

  const _TaskActionButton({
    required this.action,
    required this.taskId,
    required this.isProcessing,
    required this.onClaim,
    required this.onComplete,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final child = isProcessing
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(switch (action) {
            TaskAction.claim => i18n.taskClaimAction,
            TaskAction.complete => i18n.taskCompleteAction,
            TaskAction.reassign => i18n.taskReassignAction,
          });

    return switch (action) {
      TaskAction.claim => OutlinedButton(
        key: Key('task_claim_button_$taskId'),
        onPressed: isProcessing ? null : onClaim,
        child: child,
      ),
      TaskAction.complete => FilledButton(
        key: Key('task_complete_button_$taskId'),
        onPressed: isProcessing ? null : onComplete,
        child: child,
      ),
      TaskAction.reassign => TextButton(
        key: Key('task_reassign_button_$taskId'),
        onPressed: isProcessing ? null : onReassign,
        child: child,
      ),
    };
  }
}

class _TaskStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TaskStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

_TaskStatusPresentation _taskStatusPresentation(
  AppLocalizations i18n,
  TaskStatus status,
) {
  return switch (status) {
    TaskStatus.unassigned => _TaskStatusPresentation(
      label: i18n.taskStatusUnassigned,
      color: AppColors.onSurfaceVariant,
      icon: Icons.radio_button_unchecked_rounded,
    ),
    TaskStatus.pending => _TaskStatusPresentation(
      label: i18n.taskStatusPending,
      color: AppColors.warning,
      icon: Icons.schedule_rounded,
    ),
    TaskStatus.completed => _TaskStatusPresentation(
      label: i18n.taskStatusCompleted,
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
    ),
  };
}

class _TaskStatusPresentation {
  final String label;
  final Color color;
  final IconData icon;

  const _TaskStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });
}
