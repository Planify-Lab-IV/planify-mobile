import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class EventConfigScreen extends StatelessWidget {
  final String eventId;

  const EventConfigScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.eventConfigTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}
