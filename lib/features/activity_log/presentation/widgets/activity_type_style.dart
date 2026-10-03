import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_type.dart';

class ActivityTypeStyle {
  final IconData icon;
  final Color color;

  const ActivityTypeStyle({required this.icon, required this.color});
}

ActivityTypeStyle activityTypeStyle(
  ActivityType type,
  ColorScheme colorScheme,
) {
  return switch (type) {
    ActivityType.taskCreated => const ActivityTypeStyle(
      icon: Icons.add_task_rounded,
      color: AppColors.warning,
    ),
    ActivityType.availabilityUpdated => ActivityTypeStyle(
      icon: Icons.calendar_month_outlined,
      color: colorScheme.primary,
    ),
    ActivityType.expenseCreated => const ActivityTypeStyle(
      icon: Icons.receipt_long_outlined,
      color: AppColors.danger,
    ),
    ActivityType.scheduleConfirmed => const ActivityTypeStyle(
      icon: Icons.event_available_outlined,
      color: AppColors.success,
    ),
    ActivityType.unknown => const ActivityTypeStyle(
      icon: Icons.history_rounded,
      color: AppColors.onSurfaceVariant,
    ),
  };
}
