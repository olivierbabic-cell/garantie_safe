import 'package:flutter/material.dart';
import '../helpers/warranty_status_helper.dart';

class WarrantyProgressBar extends StatelessWidget {
  final DateTime? purchaseDate;
  final DateTime? expiryDate;

  const WarrantyProgressBar({
    super.key,
    required this.purchaseDate,
    required this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = WarrantyStatusHelper.getUrgency(purchaseDate, expiryDate);
    final remainingRatio =
        WarrantyStatusHelper.getRemainingRatio(purchaseDate, expiryDate);
    final color = WarrantyStatusHelper.getUrgencyColor(urgency);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: remainingRatio,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
