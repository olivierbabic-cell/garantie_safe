import 'package:flutter/material.dart';
import 'package:garantie_safe/core/categories.dart';
import 'package:garantie_safe/features/items/item.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/ui/components/components.dart';
import 'package:garantie_safe/branding/app_brand.dart';
import 'package:garantie_safe/theme/app_tokens.dart';
import '../helpers/warranty_status_helper.dart';

class ReceiptCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ReceiptCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(item.purchaseDate);
    final expiryDate = item.expiryDate != null
        ? DateTime.fromMillisecondsSinceEpoch(item.expiryDate!)
        : null;

    final statusText = WarrantyStatusHelper.formatStatus(
      context,
      purchaseDate,
      expiryDate,
    );

    final urgency = WarrantyStatusHelper.getUrgency(purchaseDate, expiryDate);
    final statusType = WarrantyStatusHelper.getStatusType(urgency);
    final categoryLabel = Categories.label(context, item.categoryCode);

    final brand = AppBrand.current;

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.spacing.md,
        vertical: AppTokens.spacing.sm + 2,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon + Title + Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon using new component
              AppCategoryIcon.fromCategoryId(
                categoryId: item.categoryCode ?? 'other',
              ),
              SizedBox(width: AppTokens.spacing.sm),

              // Title + Category label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        height: 1.3,
                        letterSpacing: -0.3,
                        color: brand.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTokens.spacing.xxs),
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        color: brand.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: brand.textSecondary,
                  size: 20,
                ),
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: Colors.red.shade400),
                        SizedBox(width: AppTokens.spacing.sm),
                        Text(
                          AppLocalizations.of(context)!.delete,
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),

          SizedBox(height: AppTokens.spacing.sm + 2),

          // Status badge using new component
          AppStatusBadge(
            label: statusText,
            type: statusType,
            icon: Icons.schedule_outlined,
            compact: true,
          ),

          SizedBox(height: AppTokens.spacing.xs + 1),

          // Timeline bar using new component
          AppTimelineBar.fromDates(
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
          ),
        ],
      ),
    );
  }
}
