import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/person_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/person.dart';
import '../controllers/friends_notifier.dart';
import '../controllers/friends_providers.dart';
import '../controllers/friends_state.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(friendsNotifierProvider);
    final notifier = ref.read(friendsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          i18n.friendsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 600 ? 600 : double.infinity,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        sliver: SliverList.list(
                          children: [
                            TextField(
                              key: const Key('friends_search_field'),
                              onChanged: notifier.updateSearchQuery,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                labelText: i18n.friendsSearchLabel,
                                hintText: i18n.friendsSearchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                              ),
                            ),
                            if (state.isSearchActive) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _SectionTitle(title: i18n.friendsSearchLabel),
                              const SizedBox(height: AppSpacing.sm),
                              _SearchResults(
                                state: state,
                                notifier: notifier,
                                emptyLabel: i18n.friendsSearchEmpty,
                                errorLabel: i18n.friendsSearchError,
                                retryLabel: i18n.retryButton,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              title:
                                  '${i18n.friendsRequestsTitle} · ${i18n.friendsReceivedRequestsTitle}',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _RequestsSection(
                              key: const Key('friends_requests_section'),
                              people: [
                                for (final request in state.requests.received)
                                  request.user,
                              ],
                              status: state.requestsStatus,
                              emptyLabel: i18n.friendsReceivedRequestsEmpty,
                              errorLabel: i18n.friendsLoadError,
                              retryLabel: i18n.retryButton,
                              onRetry: notifier.loadRequests,
                            ),
                            if (state.requestsStatus ==
                                    FriendsLoadStatus.success &&
                                state.requests.sent.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _SectionTitle(
                                title:
                                    '${i18n.friendsRequestsTitle} · ${i18n.friendsSentRequestsTitle}',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _RequestsSection(
                                key: const Key(
                                  'friends_sent_requests_section',
                                ),
                                people: [
                                  for (final request in state.requests.sent)
                                    request.user,
                                ],
                                status: state.requestsStatus,
                                emptyLabel: i18n.friendsReceivedRequestsEmpty,
                                errorLabel: i18n.friendsLoadError,
                                retryLabel: i18n.retryButton,
                                onRetry: notifier.loadRequests,
                                showSentStatus: true,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(title: i18n.friendsFriendsTitle),
                            const SizedBox(height: AppSpacing.sm),
                            _FriendsSection(
                              key: const Key('friends_list_section'),
                              people: state.friends,
                              status: state.friendsStatus,
                              emptyLabel: i18n.friendsFriendsEmpty,
                              errorLabel: i18n.friendsLoadError,
                              retryLabel: i18n.retryButton,
                              onRetry: notifier.loadFriends,
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
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final FriendsState state;
  final FriendsNotifier notifier;
  final String emptyLabel;
  final String errorLabel;
  final String retryLabel;

  const _SearchResults({
    required this.state,
    required this.notifier,
    required this.emptyLabel,
    required this.errorLabel,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('friends_search_results'),
      child: switch (state.searchStatus) {
        FriendsLoadStatus.loading => const _SectionLoading(),
        FriendsLoadStatus.error => _SectionError(
          message: errorLabel,
          retryLabel: retryLabel,
          onRetry: () => notifier.updateSearchQuery(state.searchQuery),
        ),
        FriendsLoadStatus.success when state.searchResults.isEmpty =>
          _SectionEmpty(message: emptyLabel),
        FriendsLoadStatus.success => _PersonCards(people: state.searchResults),
        FriendsLoadStatus.idle => const SizedBox.shrink(),
      },
    );
  }
}

class _RequestsSection extends StatelessWidget {
  final List<Person> people;
  final FriendsLoadStatus status;
  final String emptyLabel;
  final String errorLabel;
  final String retryLabel;
  final Future<void> Function() onRetry;
  final bool showSentStatus;

  const _RequestsSection({
    super.key,
    required this.people,
    required this.status,
    required this.emptyLabel,
    required this.errorLabel,
    required this.retryLabel,
    required this.onRetry,
    this.showSentStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      FriendsLoadStatus.loading => const _SectionLoading(),
      FriendsLoadStatus.error => _SectionError(
        message: errorLabel,
        retryLabel: retryLabel,
        onRetry: onRetry,
      ),
      FriendsLoadStatus.success when people.isEmpty => _SectionEmpty(
        message: emptyLabel,
      ),
      FriendsLoadStatus.success || FriendsLoadStatus.idle => _PersonCards(
        people: people,
        showSentStatus: showSentStatus,
      ),
    };
  }
}

class _FriendsSection extends StatelessWidget {
  final List<Person> people;
  final FriendsLoadStatus status;
  final String emptyLabel;
  final String errorLabel;
  final String retryLabel;
  final Future<void> Function() onRetry;

  const _FriendsSection({
    super.key,
    required this.people,
    required this.status,
    required this.emptyLabel,
    required this.errorLabel,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      FriendsLoadStatus.loading => const _SectionLoading(),
      FriendsLoadStatus.error => _SectionError(
        message: errorLabel,
        retryLabel: retryLabel,
        onRetry: onRetry,
      ),
      FriendsLoadStatus.success when people.isEmpty => _SectionEmpty(
        message: emptyLabel,
      ),
      FriendsLoadStatus.success || FriendsLoadStatus.idle => _PersonCards(
        people: people,
      ),
    };
  }
}

class _PersonCards extends StatelessWidget {
  final List<Person> people;
  final bool showSentStatus;

  const _PersonCards({required this.people, this.showSentStatus = false});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return Column(
      children: [
        for (var index = 0; index < people.length; index++) ...[
          Card(
            margin: EdgeInsets.zero,
            child: PersonRow(
              person: people[index],
              trailing: showSentStatus
                  ? _SentRequestStatus(label: i18n.friendRequestSent)
                  : null,
            ),
          ),
          if (index != people.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SentRequestStatus extends StatelessWidget {
  final String label;

  const _SentRequestStatus({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final String message;

  const _SectionEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return _SectionMessage(message: message);
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  const _SectionError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionMessage(
      message: message,
      action: TextButton(onPressed: onRetry, child: Text(retryLabel)),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  final String message;
  final Widget? action;

  const _SectionMessage({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
