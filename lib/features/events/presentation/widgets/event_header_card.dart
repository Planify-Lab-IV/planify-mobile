import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';

class EventHeaderCard extends StatelessWidget {
  final Event event;

  const EventHeaderCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
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
                event.date ?? i18n.eventDateFallback,
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

  Widget _buildStatusChip(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final isCancelled = event.isCancelled;

    final backgroundColor = isCancelled
        ? AppColors.error.withValues(alpha: 0.12)
        : AppColors.lightBlue;
    final contentColor = isCancelled ? AppColors.error : AppColors.darkBlue;
    final icon = isCancelled
        ? Icons.cancel_outlined
        : Icons.check_circle_outline_rounded;
    final label = isCancelled
        ? i18n.eventStatusCancelled
        : i18n.eventStatusActive;

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
          color: isCancelled
              ? AppColors.error
              : AppColors.primary.withValues(alpha: 0.3),
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
