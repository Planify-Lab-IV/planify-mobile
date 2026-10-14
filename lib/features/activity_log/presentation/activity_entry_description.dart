import 'package:intl/intl.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/activity_entry.dart';
import '../domain/activity_type.dart';

String activityEntryDescription(ActivityEntry entry, AppLocalizations i18n) {
  final actor = entry.actorUsername;

  switch (entry.type) {
    case ActivityType.taskCreated:
      final title = _nonEmptyString(entry.payload['title']);
      return title == null
          ? i18n.activityUnknown(actor)
          : i18n.activityTaskCreated(actor, title);
    case ActivityType.availabilityUpdated:
      return i18n.activityAvailabilityUpdated(actor);
    case ActivityType.expenseCreated:
      final description = _nonEmptyString(entry.payload['description']);
      final totalAmountCents = entry.payload['totalAmountCents'];
      if (description == null || totalAmountCents is! int) {
        return i18n.activityUnknown(actor);
      }
      final amount =
          '\$ ${formatCents(totalAmountCents, locale: i18n.localeName)}';
      return i18n.activityExpenseCreated(actor, description, amount);
    case ActivityType.scheduleConfirmed:
      final startDateTime = _dateTime(entry.payload['startDateTime']);
      if (startDateTime == null) {
        return i18n.activityUnknown(actor);
      }
      final formattedDate = DateFormat.yMd(
        i18n.localeName,
      ).add_Hm().format(startDateTime.toLocal());
      return i18n.activityScheduleConfirmed(actor, formattedDate);
    case ActivityType.unknown:
      return i18n.activityUnknown(actor);
  }
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
