import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class CreateTaskDialog extends StatefulWidget {
  final Future<bool> Function(String title) onCreate;

  const CreateTaskDialog({super.key, required this.onCreate});

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function(String title) onCreate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CreateTaskDialog(onCreate: onCreate),
    );
  }

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _titleController = TextEditingController();
  bool _isSubmitting = false;
  bool _showRequiredError = false;
  bool _showOperationError = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _showRequiredError = true;
        _showOperationError = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showRequiredError = false;
      _showOperationError = false;
    });
    final created = await widget.onCreate(title);
    if (!mounted) return;

    if (created) {
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

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        i18n.createTaskDialogTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('create_task_title_field'),
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: i18n.createTaskTitleLabel,
              hintText: i18n.createTaskTitleHint,
              errorText: _showRequiredError
                  ? i18n.createTaskTitleRequired
                  : null,
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_showRequiredError || _showOperationError) {
                setState(() {
                  _showRequiredError = false;
                  _showOperationError = false;
                });
              }
            },
          ),
          if (_showOperationError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              i18n.tasksOperationError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('create_task_cancel_button'),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(i18n.cancelButton),
        ),
        FilledButton(
          key: const Key('create_task_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(i18n.createTaskSubmit),
        ),
      ],
    );
  }
}
