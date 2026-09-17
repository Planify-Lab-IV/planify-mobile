import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';
import '../../domain/event_status.dart';

class EventHeaderCard extends StatelessWidget {
  final Event event;

  const EventHeaderCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip de estado debajo del título
        _buildStatusChip(context),
        const SizedBox(height: AppSpacing.sm),

        // Nombre del evento
        Text(
          event.name,
          key: const Key('event_detail_name'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Ubicación
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                event.location,
                key: const Key('event_detail_location'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Fecha
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _formatDate(context, event.startDateTime),
                key: const Key('event_detail_date'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime? startDateTime) {
    if (startDateTime == null) {
      return AppLocalizations.of(context)!.eventDateFallback;
    }
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(
      locale.languageCode,
    ).add_jm().format(startDateTime.toLocal());
  }

  Widget _buildStatusChip(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final (backgroundColor, contentColor, icon, label) = switch (event.status) {
      EventStatus.active => (AppColors.lightBlue, AppColors.darkBlue, Icons.calendar_month_outlined, i18n.eventStatusActive),
      EventStatus.confirmed => (AppColors.success.withValues(alpha: 0.12), AppColors.success, Icons.event_available_outlined, i18n.attendanceConfirmed),
      EventStatus.cancelled => (AppColors.error.withValues(alpha: 0.12), AppColors.error, Icons.cancel_outlined, i18n.eventStatusCancelled),
    };

    return Container(
      key: const Key('event_detail_status_chip'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: contentColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: contentColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
