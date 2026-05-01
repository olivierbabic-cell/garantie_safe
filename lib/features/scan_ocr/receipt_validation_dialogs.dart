import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';
import 'receipt_image_quality_service.dart';

/// Action chosen by user in receipt validation dialogs
enum ReceiptValidationAction {
  /// User chose to retake the photo
  retake,

  /// User chose to use the photo anyway (only in WARNING)
  useAnyway,
}

/// Shows a warning dialog when receipt quality is borderline
///
/// Returns [ReceiptValidationAction.retake] or [ReceiptValidationAction.useAnyway]
/// Returns null if dialog is dismissed
Future<ReceiptValidationAction?> showReceiptWarningDialog({
  required BuildContext context,
  required ReceiptValidationResult validation,
  required String source, // 'camera', 'file', 'pdf'
  String? imagePath,
}) async {
  final t = AppLocalizations.of(context)!;

  // Determine button text based on source
  final retakeButtonText = source == 'camera'
      ? t.receipt_validation_retake_photo
      : t.receipt_validation_choose_another;

  return showDialog<ReceiptValidationAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: AppTokens.spacing.md),
            Expanded(
              child: Text(
                t.receipt_validation_warning_title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning message
              Text(
                t.receipt_validation_warning_message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              // Show image/PDF preview (REQUIRED)
              if (imagePath != null && File(imagePath).existsSync()) ...[
                SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    minHeight: 250,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radii.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radii.md),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],

              // Spacing before buttons
              SizedBox(height: 20),

              // Secondary button (Retake/Choose another)
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, ReceiptValidationAction.retake),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    retakeButtonText,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),

              // Spacing between buttons
              SizedBox(height: 12),

              // Primary button (Use anyway)
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, ReceiptValidationAction.useAnyway),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    t.receipt_validation_use_anyway,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [], // Empty - buttons are in content
      );
    },
  );
}

/// Shows a rejection dialog when file cannot be processed (technical error)
///
/// Returns [ReceiptValidationAction.retake] when user confirms
/// Returns null if dialog is dismissed
Future<ReceiptValidationAction?> showReceiptRejectDialog({
  required BuildContext context,
  required ReceiptValidationResult validation,
  required String source, // 'camera', 'file', 'pdf'
  String? imagePath, // Added to show preview
}) async {
  final t = AppLocalizations.of(context)!;

  // Determine button text based on source
  final retakeButtonText = source == 'camera'
      ? t.receipt_validation_retake_photo
      : t.receipt_validation_choose_another;

  return showDialog<ReceiptValidationAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: 28,
            ),
            SizedBox(width: AppTokens.spacing.md),
            Expanded(
              child: Text(
                t.receipt_validation_reject_title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              Text(
                t.receipt_validation_reject_message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              // Show image/PDF preview (REQUIRED)
              if (imagePath != null && File(imagePath).existsSync()) ...[
                SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    minHeight: 250,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radii.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radii.md),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],

              // Spacing before button
              SizedBox(height: 20),

              // Primary action button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, ReceiptValidationAction.retake),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    retakeButtonText,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [], // Empty - button is in content
      );
    },
  );
}
