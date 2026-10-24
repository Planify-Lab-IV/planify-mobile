import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
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
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      appBar: AppBar(
        title: Text(
          i18n.profileTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
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
            onDiscardAvatarAndSaveName: _discardAvatarAndSaveName,
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

  Future<void> _discardAvatarAndSaveName() async {
    ref.read(profileNotifierProvider.notifier).discardPendingAvatar();
    await _save();
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileState state;
  final TextEditingController nameController;
  final ImageProvider<Object>? Function(String filePath)? avatarImageProvider;
  final ValueChanged<String> onNameChanged;
  final Future<void> Function() onAvatarPressed;
  final Future<void> Function() onSave;
  final Future<void> Function() onDiscardAvatarAndSaveName;

  const _ProfileContent({
    required this.state,
    required this.nameController,
    required this.avatarImageProvider,
    required this.onNameChanged,
    required this.onAvatarPressed,
    required this.onSave,
    required this.onDiscardAvatarAndSaveName,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = state.profile!;
    final pendingAvatarPath = state.pendingAvatarFilePath;
    final imageProvider = pendingAvatarPath != null
        ? avatarImageProvider?.call(pendingAvatarPath) ??
              FileImage(File(pendingAvatarPath))
        : profile.avatarUrl == null
        ? null
        : avatarImageProvider?.call(profile.avatarUrl!) ??
              NetworkImage(profile.avatarUrl!);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            key: const Key('profile_content'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                key: const Key('profile_content_card'),
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                child: Column(
                  key: const Key('profile_identity_header'),
                  children: [
                    Semantics(
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
                              radius: 36,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.secondaryContainer,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    color: theme.colorScheme.onPrimary,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: IntrinsicWidth(
                            child: TextField(
                              key: const Key('profile_name_field'),
                              controller: nameController,
                              enabled: !state.isSaving,
                              maxLength: 80,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.words,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                filled: false,
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xs,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onChanged: onNameChanged,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReadOnlyProfileField(
                key: const Key('profile_email_field'),
                value: profile.email,
                icon: Icons.email_outlined,
                semanticLabel: i18n.profileEmailLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileNavigationTile(
                key: const Key('profile_friends_button'),
                label: i18n.profileFriendsAction,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
              ),
              if (state.hasSaveError) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.saveFailure ==
                          ProfileSaveFailure.avatarStorageUnavailable
                      ? i18n.profileAvatarStorageUnavailable
                      : i18n.profileSaveError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.saveFailure ==
                        ProfileSaveFailure.avatarStorageUnavailable &&
                    pendingAvatarPath != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    key: const Key(
                      'profile_discard_avatar_and_save_name_button',
                    ),
                    onPressed: onDiscardAvatarAndSaveName,
                    child: Text(i18n.profileDiscardAvatarAndSaveName),
                  ),
                ],
              ],
              if (state.canSave || state.isSaving) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String? semanticLabel;
  final String value;
  final IconData icon;

  const _ReadOnlyProfileField({
    super.key,
    this.semanticLabel,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      readOnly: true,
      label: semanticLabel,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNavigationTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ProfileNavigationTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
            ],
          ),
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
