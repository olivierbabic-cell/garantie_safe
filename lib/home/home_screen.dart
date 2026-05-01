import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../features/items/item_edit_screen.dart';
import '../features/scan_ocr/receipt_text_extraction_service.dart';
import '../features/scan_ocr/receipt_parser_service.dart';
import '../features/scan_ocr/receipt_image_quality_service.dart';
import '../features/scan_ocr/receipt_validation_dialogs.dart';
import '../features/items/multi_item_receipt_screen.dart';
import '../features/items/items_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/widgets/import_source_sheet.dart';
import '../branding/app_brand.dart';
import '../theme/functional_colors.dart';

// Design constants for crisp, premium tile appearance
const double _kGridSpacing = 14.0;
const double _kGridPadding = 20.0;
const double _kTileBorderRadius = 22.0;
const double _kTileBorderWidth = 1.0;
const double _kTilePadding = 20.0;
const double _kIconSize = 36.0;
const double _kShadowBlurRadius = 12.0;
const double _kShadowOpacity = 0.08;
const double _kAppIconSize = 56.0;
const double _kTopSectionPadding = 24.0;
const double _kStatusCardRadius = 16.0;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _processing = false;

  /// Scan with camera
  Future<void> _scanWithCamera() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _processing = true);

    try {
      debugPrint('HomeScreen: Camera photo captured: ${pickedFile.path}');

      // Extract text from image using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromImage(pickedFile.path);

      debugPrint(
          'HomeScreen: OCR extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'HomeScreen: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      debugPrint('HomeScreen: Starting quality validation');
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'home_camera',
      );

      // Dismiss loading indicator
      if (mounted) {
        setState(() => _processing = false);
      }

      // Handle validation result
      if (validation.isReject) {
        debugPrint(
            'HomeScreen: Quality result = REJECT - ${validation.reason}');
        debugPrint('HomeScreen: Blocked by quality validation');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'camera',
          imagePath: pickedFile.path,
        );
        // User must retake - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint(
            'HomeScreen: Quality result = WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'camera',
          imagePath: pickedFile.path,
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('HomeScreen: User chose to retake photo');
          debugPrint('HomeScreen: Blocked by quality validation');
          return; // Exit without processing
        }
        debugPrint('HomeScreen: User chose to use photo anyway');
        debugPrint('HomeScreen: Continuing to OCR/parser after user override');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('HomeScreen: Quality result = ACCEPT');
        debugPrint('HomeScreen: Continuing to OCR/parser');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(pickedFile.path);

      if (!mounted) return;

      // Show multi-item choice if we have useful data
      await _showMultiItemChoice(parsedData, attachmentPath);
    } catch (e) {
      debugPrint('HomeScreen: Camera scan error: $e');
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Import from gallery or files - shows source picker
  Future<void> _importFile() async {
    final source = await showImportSourcePicker(context);

    if (source == null) return;

    switch (source) {
      case 'photo':
        await _importPhoto();
        break;
      case 'pdf':
        await _importPdf();
        break;
    }
  }

  /// Import photo from gallery
  Future<void> _importPhoto() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _processing = true);

    try {
      debugPrint('HomeScreen: Gallery photo selected: ${pickedFile.path}');

      // Extract text from image using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromImage(pickedFile.path);

      debugPrint(
          'HomeScreen: OCR extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'HomeScreen: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      debugPrint('HomeScreen: Starting quality validation');
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'home_gallery',
      );

      // Dismiss loading indicator
      if (mounted) {
        setState(() => _processing = false);
      }

      // Handle validation result
      if (validation.isReject) {
        debugPrint(
            'HomeScreen: Quality result = REJECT - ${validation.reason}');
        debugPrint('HomeScreen: Blocked by quality validation');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'file',
          imagePath: pickedFile.path,
        );
        // User must retake - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint(
            'HomeScreen: Quality result = WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'file',
          imagePath: pickedFile.path,
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('HomeScreen: User chose to retake photo');
          debugPrint('HomeScreen: Blocked by quality validation');
          return; // Exit without processing
        }
        debugPrint('HomeScreen: User chose to use photo anyway');
        debugPrint('HomeScreen: Continuing to OCR/parser after user override');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('HomeScreen: Quality result = ACCEPT');
        debugPrint('HomeScreen: Continuing to OCR/parser');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(pickedFile.path);

      if (!mounted) return;

      // Show multi-item choice if we have useful data
      await _showMultiItemChoice(parsedData, attachmentPath);
    } catch (e) {
      debugPrint('HomeScreen: Photo import error: $e');
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Import PDF document
  Future<void> _importPdf() async {
    final t = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.scan_file_access_error)),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      debugPrint('HomeScreen: PDF selected: $filePath');

      // Extract text from PDF using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromPdf(filePath);

      debugPrint(
          'HomeScreen: PDF extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'HomeScreen: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      debugPrint('HomeScreen: Starting quality validation');
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'home_pdf',
      );

      // Dismiss loading indicator
      if (mounted) {
        setState(() => _processing = false);
      }

      // Handle validation result
      if (validation.isReject) {
        debugPrint(
            'HomeScreen: Quality result = REJECT - ${validation.reason}');
        debugPrint('HomeScreen: Blocked by quality validation');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: filePath,
        );
        // User must retake/re-select - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint(
            'HomeScreen: Quality result = WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: null, // PDF has no image preview
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('HomeScreen: User chose to re-select PDF');
          debugPrint('HomeScreen: Blocked by quality validation');
          return; // Exit without processing
        }
        debugPrint('HomeScreen: User chose to use PDF anyway');
        debugPrint('HomeScreen: Continuing to OCR/parser after user override');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('HomeScreen: Quality result = ACCEPT');
        debugPrint('HomeScreen: Continuing to OCR/parser');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(filePath);

      if (!mounted) return;

      // Show multi-item choice if we have useful data
      await _showMultiItemChoice(parsedData, attachmentPath);
    } catch (e) {
      debugPrint('HomeScreen: PDF import error: $e');
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Copy file to attachments directory
  Future<String> _copyToAttachments(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final extension = p.extension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = 'scanned_$timestamp$extension';
    final targetPath = '${attachmentsDir.path}/$newFileName';

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Show multi-item choice dialog
  Future<void> _showMultiItemChoice(
    ReceiptScanDraft parsedData,
    String attachmentPath,
  ) async {
    final t = AppLocalizations.of(context)!;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.multi_item_choice_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.multi_item_choice_subtitle),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.inventory_2, color: Colors.white),
              ),
              title: Text(t.multi_item_create_one),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'single'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.inventory, color: Colors.white),
              ),
              title: Text(t.multi_item_create_multiple),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'multi'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (choice == 'multi') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiItemReceiptScreen(
            scannedData: parsedData,
            receiptFilePath: attachmentPath,
          ),
        ),
      );
    } else if (choice == 'single') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemEditScreen(
            scannedData: parsedData,
            scannedFilePath: attachmentPath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(itemsListProvider);

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: SafeArea(
        child: _processing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppBrand.current.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.scan_extracting_text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Branded top section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kTopSectionPadding,
                      _kTopSectionPadding,
                      _kTopSectionPadding,
                      16,
                    ),
                    child: Row(
                      children: [
                        // App icon/logo placeholder
                        Container(
                          width: _kAppIconSize,
                          height: _kAppIconSize,
                          decoration: BoxDecoration(
                            color: AppBrand.current.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppBrand.current.primary
                                  .withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: AppBrand.current.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.home_title,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: AppBrand.current.textPrimary,
                                  letterSpacing: -0.8,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.home_subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppBrand.current.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Premium tile grid
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _kGridPadding,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: _kGridSpacing,
                      crossAxisSpacing: _kGridSpacing,
                      childAspectRatio: 1.0,
                      children: [
                        _PremiumTile(
                          icon: Icons.camera_alt,
                          title: t.home_scan,
                          accentColor: AppBrand.current.primary,
                          onTap: _scanWithCamera,
                        ),
                        _PremiumTile(
                          icon: Icons.upload_file,
                          title: t.home_import,
                          accentColor: AppSemanticColors.success,
                          onTap: _importFile,
                        ),
                        _PremiumTile(
                          icon: Icons.receipt_long,
                          title: t.home_receipts,
                          accentColor: AppSemanticColors.warning,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/items'),
                        ),
                        _PremiumTile(
                          icon: Icons.settings,
                          title: t.home_settings,
                          accentColor: AppBrand.current.primaryDark,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/settings'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kGridPadding,
                      0,
                      _kGridPadding,
                      _kTopSectionPadding,
                    ),
                    child: itemsAsync.when(
                      data: (items) {
                        final activeCount = items.length;
                        final expiringCount = items.where((item) {
                          if (item.expiryDate == null) return false;
                          final expiryDateTime =
                              DateTime.fromMillisecondsSinceEpoch(
                            item.expiryDate!,
                          );
                          final daysUntil =
                              expiryDateTime.difference(DateTime.now()).inDays;
                          return daysUntil >= 0 && daysUntil <= 30;
                        }).length;

                        return _StatusCard(
                          activeCount: activeCount,
                          expiringCount: expiringCount,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
      ),
    );
  }
}

/// Premium tile with crisp borders, subtle shadow, and clean design
class _PremiumTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;

  const _PremiumTile({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PremiumTile> createState() => _PremiumTileState();
}

class _PremiumTileState extends State<_PremiumTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Light tint for tile background - single unified surface
    final tileTint = widget.accentColor.withValues(alpha: 0.10);
    // Darker icon color for clarity
    final iconColor = Color.alphaBlend(
      widget.accentColor.withValues(alpha: 0.85),
      AppBrand.current.textPrimary,
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: tileTint,
            borderRadius: BorderRadius.circular(_kTileBorderRadius),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
              width: _kTileBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _kShadowOpacity),
                blurRadius: _kShadowBlurRadius,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(_kTilePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon directly on tile surface - no container
                Icon(
                  widget.icon,
                  size: _kIconSize,
                  color: iconColor,
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppBrand.current.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact status card to reduce empty space and provide context
class _StatusCard extends ConsumerWidget {
  final int activeCount;
  final int expiringCount;

  const _StatusCard({
    required this.activeCount,
    required this.expiringCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppBrand.current.background,
        borderRadius: BorderRadius.circular(_kStatusCardRadius),
        border: Border.all(
          color: AppBrand.current.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Active items
          Expanded(
            child: _StatusItem(
              icon: Icons.description_outlined,
              label: t.home_status_active_items(activeCount),
              color: AppBrand.current.primary,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 32,
            color: AppBrand.current.border,
          ),
          const SizedBox(width: 16),
          // Expiring soon
          Expanded(
            child: expiringCount > 0
                ? _StatusItem(
                    icon: Icons.schedule_outlined,
                    label: t.home_status_expiring_soon(expiringCount),
                    color: AppSemanticColors.warning,
                  )
                : _StatusItem(
                    icon: Icons.check_circle_outline,
                    label: t.home_status_all_good,
                    color: AppSemanticColors.success,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual status item within the status card
class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
