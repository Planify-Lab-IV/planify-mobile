import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../controllers/profile_providers.dart';
import '../controllers/profile_state.dart';

ImageProvider<Object> profileAvatarImageProvider(String path) {
  final scheme = Uri.tryParse(path)?.scheme.toLowerCase();
  if (scheme == 'blob' || scheme == 'http' || scheme == 'https') {
    return NetworkImage(path);
  }

  return FileImage(File(path));
}

class ProfileScreen extends ConsumerStatefulWidget {
  final ImageProvider<Object>? Function(String filePath)? avatarImageProvider;

  const ProfileScreen({super.key, this.avatarImageProvider});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final state = ref.watch(profileNotifierProvider);

    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      if (previous?.profile != next.profile && next.profile != null) {
        _nameController.value = TextEditingValue(
          text: next.draftName,
          selection: TextSelection.collapsed(offset: next.draftName.length),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.profileTitle),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: switch (state.loadStatus) {
          ProfileLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ProfileLoadStatus.error => _ProfileLoadError(
            message: i18n.profileLoadError,
            retryLabel: i18n.retryButton,
            onRetry: ref.read(profileNotifierProvider.notifier).load,
          ),
          ProfileLoadStatus.success => _ProfileContent(
            state: state,
            nameController: _nameController,
            avatarImageProvider: widget.avatarImageProvider,
            onNameChanged: ref
                .read(profileNotifierProvider.notifier)
                .updateDraftName,
            onAvatarPressed: _pickAvatar,
            onSave: _save,
          ),
        },
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final i18n = AppLocalizations.of(context)!;
    String? path;
    try {
      path = await ref.read(avatarPickerProvider).pickAvatar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('profile_avatar_picker_error_snackbar'),
            content: Text(i18n.profileSaveError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (path == null || !mounted) return;

    ref.read(profileNotifierProvider.notifier).selectAvatar(path);
  }

  Future<void> _save() async {
    final previousState = ref.read(profileNotifierProvider);
    final previousName = previousState.profile?.name;
    final requestedName = previousState.trimmedDraftName;
    final shouldUpdateSessionName =
        previousName != null && requestedName != previousName;

    await ref.read(profileNotifierProvider.notifier).save();
    if (!mounted) return;

    final state = ref.read(profileNotifierProvider);
    final profile = state.profile;
    if (shouldUpdateSessionName &&
        !state.hasPendingChanges &&
        !state.hasSaveError &&
        profile != null) {
      ref.read(authNotifierProvider.notifier).updateSessionName(profile.name);
    }
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileState state;
  final TextEditingController nameController;
  final ImageProvider<Object>? Function(String filePath)? avatarImageProvider;
  final ValueChanged<String> onNameChanged;
  final Future<void> Function() onAvatarPressed;
  final Future<void> Function() onSave;

  const _ProfileContent({
    required this.state,
    required this.nameController,
    required this.avatarImageProvider,
    required this.onNameChanged,
    required this.onAvatarPressed,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = state.profile!;
    final imagePath = state.pendingAvatarFilePath ?? profile.avatarUrl;
    final imageProvider = imagePath == null
        ? null
        : avatarImageProvider?.call(imagePath) ??
              profileAvatarImageProvider(imagePath);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Semantics(
                      button: true,
                      label: i18n.profileChangeAvatar,
                      child: InkWell(
                        key: const Key('profile_avatar_button'),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: state.isSaving ? null : onAvatarPressed,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InitialsAvatar(
                              name: state.draftName,
                              imageProvider: imageProvider,
                              radius: 52,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    color: theme.colorScheme.onPrimary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    key: const Key('profile_name_field'),
                    controller: nameController,
                    enabled: !state.isSaving,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: i18n.profileNameLabel,
                    ),
                    onChanged: onNameChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReadOnlyProfileField(
                    label: i18n.profileUsernameLabel,
                    value: profile.username,
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadOnlyProfileField(
                    label: i18n.profileEmailLabel,
                    value: profile.email,
                    icon: Icons.email_outlined,
                  ),
                  if (state.hasSaveError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      i18n.profileSaveError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    key: const Key('profile_save_button'),
                    onPressed: state.canSave ? onSave : null,
                    child: state.isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(i18n.profileSaveButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      readOnly: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ProfileLoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        key: const Key('profile_load_error'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('profile_retry_button'),
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
