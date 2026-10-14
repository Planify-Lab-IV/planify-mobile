import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';

class ReassignTaskDialog extends StatefulWidget {
  final List<EventParticipant> participants;
  final Future<bool> Function(String participantId) onAssign;

  const ReassignTaskDialog({
    super.key,
    required this.participants,
    required this.onAssign,
  });

  static Future<void> show(
    BuildContext context, {
    required List<EventParticipant> participants,
    required Future<bool> Function(String participantId) onAssign,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          ReassignTaskDialog(participants: participants, onAssign: onAssign),
    );
  }

  @override
  State<ReassignTaskDialog> createState() => _ReassignTaskDialogState();
}

class _ReassignTaskDialogState extends State<ReassignTaskDialog> {
  String? _selectedParticipantId;
  bool _isSubmitting = false;
  bool _showSelectionError = false;
  bool _showOperationError = false;

  Future<void> _submit() async {
    final participantId = _selectedParticipantId;
    if (participantId == null) {
      setState(() {
        _showSelectionError = true;
        _showOperationError = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showSelectionError = false;
      _showOperationError = false;
    });
    final assigned = await widget.onAssign(participantId);
    if (!mounted) return;

    if (assigned) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSubmitting = false;
      _showOperationError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final availableDialogHeight = math.max(
      180.0,
      MediaQuery.sizeOf(context).height -
          viewInsets.bottom -
          (AppSpacing.lg * 2),
    );
    final desiredDialogHeight =
        180.0 + math.min(widget.participants.length * 56.0, 320.0);
    final dialogHeight = math.min(desiredDialogHeight, availableDialogHeight);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: SizedBox(
        height: dialogHeight,
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                i18n.reassignTaskDialogTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                i18n.reassignTaskParticipantLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RadioGroup<String>(
                  groupValue: _selectedParticipantId,
                  onChanged: (participantId) {
                    if (_isSubmitting) return;
                    setState(() {
                      _selectedParticipantId = participantId;
                      _showSelectionError = false;
                      _showOperationError = false;
                    });
                  },
                  child: ListView.builder(
                    key: const Key('reassign_task_participants_list'),
                    itemCount: widget.participants.length,
                    itemBuilder: (context, index) {
                      final participant = widget.participants[index];
                      return RadioListTile<String>(
                        key: Key('reassign_task_participant_${participant.id}'),
                        value: participant.id,
                        title: Text(participant.username),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ),
              ),
              if (_showSelectionError || _showOperationError) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _showSelectionError
                      ? i18n.reassignTaskParticipantRequired
                      : i18n.tasksOperationError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    key: const Key('reassign_task_cancel_button'),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(i18n.cancelButton),
                  ),
                  FilledButton(
                    key: const Key('reassign_task_submit_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(i18n.reassignTaskConfirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
