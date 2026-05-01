import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/theme/functional_colors.dart';
import 'package:garantie_safe/ui/components/app_status_badge.dart';
import 'package:garantie_safe/ui/components/app_timeline_bar.dart';

enum WarrantyUrgency {
  safe, // > 60% remaining
  moderate, // 30-60% remaining
  urgent, // < 30% remaining
  expired, // past expiry
  none, // no warranty set
}

class WarrantyStatusHelper {
  /// Calculate warranty urgency level based on percentage remaining
  static WarrantyUrgency getUrgency(
      DateTime? purchaseDate, DateTime? expiryDate) {
    if (expiryDate == null) return WarrantyUrgency.none;

    final now = DateTime.now();

    // Check if expired
    if (now.isAfter(expiryDate)) return WarrantyUrgency.expired;

    // Calculate percentage remaining
    if (purchaseDate != null && purchaseDate.isBefore(expiryDate)) {
      final totalDuration = expiryDate.difference(purchaseDate).inMilliseconds;
      final remaining = expiryDate.difference(now).inMilliseconds;
      final percentageRemaining = (remaining / totalDuration) * 100;

      if (percentageRemaining > 60) return WarrantyUrgency.safe;
      if (percentageRemaining > 30) return WarrantyUrgency.moderate;
      return WarrantyUrgency.urgent;
    }

    // Fallback to days-based if no purchase date
    final daysRemaining = expiryDate.difference(now).inDays;
    if (daysRemaining > 90) return WarrantyUrgency.safe;
    if (daysRemaining > 30) return WarrantyUrgency.moderate;
    return WarrantyUrgency.urgent;
  }

  /// Get color for urgency level using semantic colors
  static Color getUrgencyColor(WarrantyUrgency urgency) {
    switch (urgency) {
      case WarrantyUrgency.safe:
        return AppSemanticColors.success;
      case WarrantyUrgency.moderate:
        return AppSemanticColors.warning;
      case WarrantyUrgency.urgent:
        return AppSemanticColors.error;
      case WarrantyUrgency.expired:
      case WarrantyUrgency.none:
        return AppSemanticColors.error.withValues(alpha: 0.5);
    }
  }

  /// Convert WarrantyUrgency to AppStatusType
  static AppStatusType getStatusType(WarrantyUrgency urgency) {
    switch (urgency) {
      case WarrantyUrgency.safe:
        return AppStatusType.active;
      case WarrantyUrgency.moderate:
        return AppStatusType.expiring;
      case WarrantyUrgency.urgent:
        return AppStatusType.expiring;
      case WarrantyUrgency.expired:
        return AppStatusType.expired;
      case WarrantyUrgency.none:
        return AppStatusType.noWarranty;
    }
  }

  /// Convert WarrantyUrgency to TimelineUrgency
  static TimelineUrgency getTimelineUrgency(WarrantyUrgency urgency) {
    switch (urgency) {
      case WarrantyUrgency.safe:
        return TimelineUrgency.safe;
      case WarrantyUrgency.moderate:
        return TimelineUrgency.moderate;
      case WarrantyUrgency.urgent:
        return TimelineUrgency.urgent;
      case WarrantyUrgency.expired:
      case WarrantyUrgency.none:
        return TimelineUrgency.expired;
    }
  }

  /// Calculate REMAINING warranty ratio (0.0 to 1.0)
  /// At purchase = 1.0 (full bar), at expiry = 0.0 (empty bar)
  static double getRemainingRatio(
      DateTime? purchaseDate, DateTime? expiryDate) {
    if (purchaseDate == null || expiryDate == null) return 0.0;

    final now = DateTime.now();
    final totalDuration = expiryDate.difference(purchaseDate).inMilliseconds;
    final elapsed = now.difference(purchaseDate).inMilliseconds;

    if (totalDuration <= 0) return 0.0;

    // Calculate remaining (inverse of elapsed)
    final remaining = 1.0 - (elapsed / totalDuration);
    return remaining.clamp(0.0, 1.0);
  }

  /// Format warranty status text
  static String formatStatus(
    BuildContext context,
    DateTime? purchaseDate,
    DateTime? expiryDate,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (expiryDate == null) {
      return l10n.status_no_warranty;
    }

    final now = DateTime.now();
    final daysRemaining = expiryDate.difference(now).inDays;

    // Expired
    if (daysRemaining < 0) {
      final daysExpired = -daysRemaining;
      if (daysExpired < 30) {
        return l10n.status_expired_recently;
      } else if (daysExpired < 365) {
        return l10n.status_expired;
      } else {
        final yearsExpired = (daysExpired / 365).floor();
        if (yearsExpired == 1) {
          return l10n.status_expired_year_ago;
        } else {
          return l10n.status_expired_years_ago(yearsExpired);
        }
      }
    }

    // Expires today
    if (daysRemaining == 0) {
      return l10n.status_today;
    }

    // Less than 30 days - show in days
    if (daysRemaining < 30) {
      return l10n.status_expiring_in_days(daysRemaining);
    }

    // Less than 365 days - show in months
    if (daysRemaining < 365) {
      final monthsRemaining = (daysRemaining / 30).floor();
      if (monthsRemaining == 1) {
        return l10n.status_month_left;
      } else {
        return l10n.status_months_left(monthsRemaining);
      }
    }

    // More than 365 days - show in years and months
    final yearsRemaining = (daysRemaining / 365).floor();
    final monthsRemaining = ((daysRemaining % 365) / 30).floor();

    if (yearsRemaining == 1) {
      if (monthsRemaining == 0 || monthsRemaining < 2) {
        return l10n.status_year_left;
      } else {
        return l10n.status_years_months_left(1, monthsRemaining);
      }
    } else {
      if (monthsRemaining == 0 || monthsRemaining < 2) {
        return l10n.status_years_left(yearsRemaining);
      } else {
        return l10n.status_years_months_left(yearsRemaining, monthsRemaining);
      }
    }
  }
}
