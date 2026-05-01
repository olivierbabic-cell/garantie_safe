import 'package:flutter/material.dart';
import '../../branding/app_brand.dart';
import '../../branding/brand_config.dart';
import '../../theme/app_tokens.dart';
import '../../theme/functional_colors.dart';

/// Timeline bar urgency level
enum TimelineUrgency {
  safe,
  moderate,
  urgent,
  expired,
}

/// Reusable timeline/progress bar component
///
/// Displays warranty or time-based progress with:
/// - Visual representation of remaining time
/// - Semantic color coding (green, orange, red, grey)
/// - Smooth fill animation
/// - Rounded pill shape
///
/// Can be used with dates or with a manual ratio and urgency.
///
/// Usage with dates:
/// ```dart
/// AppTimelineBar.fromDates(
///   purchaseDate: DateTime.now(),
///   expiryDate: DateTime.now().add(Duration(days: 365)),
/// )
/// ```
///
/// Usage with manual ratio:
/// ```dart
/// AppTimelineBar(
///   remainingRatio: 0.7,
///   urgency: TimelineUrgency.safe,
/// )
/// ```
class AppTimelineBar extends StatelessWidget {
  final double remainingRatio;
  final TimelineUrgency urgency;
  final double height;
  final bool showPercentage;

  const AppTimelineBar({
    super.key,
    required this.remainingRatio,
    required this.urgency,
    this.height = 7,
    this.showPercentage = false,
  });

  /// Create from purchase and expiry dates
  factory AppTimelineBar.fromDates({
    required DateTime? purchaseDate,
    required DateTime? expiryDate,
    double height = 7,
    bool showPercentage = false,
  }) {
    final urgency = _calculateUrgency(purchaseDate, expiryDate);
    final ratio = _calculateRatio(purchaseDate, expiryDate);

    return AppTimelineBar(
      remainingRatio: ratio,
      urgency: urgency,
      height: height,
      showPercentage: showPercentage,
    );
  }

  static TimelineUrgency _calculateUrgency(
    DateTime? purchaseDate,
    DateTime? expiryDate,
  ) {
    if (expiryDate == null) return TimelineUrgency.expired;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) {
      return TimelineUrgency.expired;
    }

    if (purchaseDate == null) {
      // If no purchase date, assume safe
      return TimelineUrgency.safe;
    }

    final totalDuration = expiryDate.difference(purchaseDate);
    final remaining = expiryDate.difference(now);

    if (totalDuration.inDays <= 0) {
      return TimelineUrgency.expired;
    }

    final percentRemaining = (remaining.inDays / totalDuration.inDays) * 100;

    if (percentRemaining > 25) {
      return TimelineUrgency.safe;
    } else if (percentRemaining > 10) {
      return TimelineUrgency.moderate;
    } else if (percentRemaining > 0) {
      return TimelineUrgency.urgent;
    } else {
      return TimelineUrgency.expired;
    }
  }

  static double _calculateRatio(
    DateTime? purchaseDate,
    DateTime? expiryDate,
  ) {
    if (expiryDate == null) return 0.0;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) {
      return 0.0;
    }

    if (purchaseDate == null) {
      return 1.0;
    }

    final totalDuration = expiryDate.difference(purchaseDate);
    final remaining = expiryDate.difference(now);

    if (totalDuration.inDays <= 0) {
      return 0.0;
    }

    final ratio = remaining.inDays / totalDuration.inDays;
    return ratio.clamp(0.0, 1.0);
  }

  Color _getColor() {
    switch (urgency) {
      case TimelineUrgency.safe:
        return AppSemanticColors.success;
      case TimelineUrgency.moderate:
        return AppSemanticColors.warning;
      case TimelineUrgency.urgent:
        return AppSemanticColors.error;
      case TimelineUrgency.expired:
        return AppBrand.current.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final brand = AppBrand.current;

    if (showPercentage) {
      return Row(
        children: [
          Expanded(
            child: _buildBar(brand, color),
          ),
          SizedBox(width: AppTokens.spacing.sm),
          Text(
            '${(remainingRatio * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return _buildBar(brand, color);
  }

  Widget _buildBar(AppBrandConfig brand, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: brand.background,
          border: Border.all(
            color: brand.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: remainingRatio,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}
