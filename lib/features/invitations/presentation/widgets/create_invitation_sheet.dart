import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/invitation_exceptions.dart';
import '../controllers/create_invitation_state.dart';
import '../controllers/invitation_providers.dart';

class CreateInvitationSheet extends ConsumerStatefulWidget {
  final String eventId;

  const CreateInvitationSheet({super.key, required this.eventId});

  static Future<void> show(BuildContext context, {required String eventId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => CreateInvitationSheet(eventId: eventId),
    );
  }

  @override
  ConsumerState<CreateInvitationSheet> createState() =>
      _CreateInvitationSheetState();
}

class _CreateInvitationSheetState extends ConsumerState<CreateInvitationSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(createInvitationNotifierProvider(widget.eventId).notifier)
          .createInvitation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createInvitationNotifierProvider(widget.eventId));
    final notifier = ref.read(
      createInvitationNotifierProvider(widget.eventId).notifier,
    );
    final i18n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: switch (state) {
            CreateInvitationInitial() || CreateInvitationLoading() =>
              _LoadingContent(message: i18n.invitationCreateLoading),
            CreateInvitationSuccess(:final invitationUrl) => _SuccessContent(
              invitationUrl: invitationUrl,
              title: i18n.invitationCreateTitle,
              copyLabel: i18n.invitationCreateCopy,
              copiedMessage: i18n.invitationCreateCopied,
            ),
            CreateInvitationError(:final exception) => _ErrorContent(
              message: _messageFor(exception, i18n),
              retryLabel: i18n.retryButton,
              onRetry: notifier.createInvitation,
            ),
          },
        ),
      ),
    );
  }

  String _messageFor(InvitationException exception, AppLocalizations i18n) {
    return switch (exception) {
      InvitationCreationForbiddenException() => i18n.invitationCreateForbidden,
      InvitationEventNotFoundException() => i18n.invitationCreateNotFound,
      InvitationEventUnavailableException() => i18n.invitationCreateUnavailable,
      NetworkInvitationException() => i18n.invitationCreateNetworkError,
      _ => i18n.invitationCreateError,
    };
  }
}

class _LoadingContent extends StatelessWidget {
  final String message;

  const _LoadingContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Semantics(
          key: const Key('create_invitation_loading'),
          label: message,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _SuccessContent extends StatefulWidget {
  final String invitationUrl;
  final String title;
  final String copyLabel;
  final String copiedMessage;

  const _SuccessContent({
    required this.invitationUrl,
    required this.title,
    required this.copyLabel,
    required this.copiedMessage,
  });

  @override
  State<_SuccessContent> createState() => _SuccessContentState();
}

class _SuccessContentState extends State<_SuccessContent> {
  var _copied = false;
  Timer? _resetCopyStateTimer;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.invitationUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetCopyStateTimer?.cancel();
    _resetCopyStateTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _resetCopyStateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('create_invitation_success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SelectableText(
          widget.invitationUrl,
          key: const Key('create_invitation_url'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const Key('create_invitation_copy_button'),
          onPressed: _copy,
          style: _copied
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onSuccess,
                )
              : null,
          icon: Icon(_copied ? Icons.check_rounded : Icons.copy_outlined),
          label: Text(_copied ? widget.copiedMessage : widget.copyLabel),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorContent({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 180),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('create_invitation_retry_button'),
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
