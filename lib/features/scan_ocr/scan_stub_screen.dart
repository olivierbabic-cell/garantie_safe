import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'receipt_text_extraction_service.dart';
import 'receipt_parser_service.dart';
import 'receipt_image_quality_service.dart';
import 'receipt_validation_dialogs.dart';
import '../items/item_edit_screen.dart';
import '../items/multi_item_receipt_screen.dart';

class ScanStubScreen extends StatefulWidget {
  const ScanStubScreen({super.key});

  @override
  State<ScanStubScreen> createState() => _ScanStubScreenState();
}

class _ScanStubScreenState extends State<ScanStubScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.scan_title)),
      body: _processing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t.scan_extracting_text),
                  const SizedBox(height: 8),
                  Text(
                    t.scan_extracting_wait,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  t.scan_choose_source,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  t.scan_choose_source_sub,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Take Photo
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                    title: Text(t.scan_take_photo),
                    subtitle: Text(t.scan_take_photo_sub),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _takePhoto,
                  ),
                ),
                const SizedBox(height: 12),

                // Upload Receipt (Images or PDF)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.upload_file, color: Colors.white),
                    ),
                    title: Text(t.scan_upload_receipt),
                    subtitle: Text(t.scan_upload_receipt_sub),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _uploadReceipt,
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                Text(
                  t.scan_how_it_works,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  t.scan_how_it_works_steps,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    await _processImage(pickedFile.path);
  }

  Future<void> _uploadReceipt() async {
    final t = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) {
      _showError(t.scan_file_access_error);
      return;
    }

    await _processFile(filePath);
  }

  Future<void> _processFile(String filePath) async {
    final t = AppLocalizations.of(context)!;
    final extension = p.extension(filePath).toLowerCase();

    // Determine file type and route to appropriate processing
    if (extension == '.pdf') {
      await _processPdf(filePath);
    } else if (['.jpg', '.jpeg', '.png', '.heic'].contains(extension)) {
      await _processImage(filePath);
    } else {
      _showError(t.scan_unsupported_file_type(extension));
    }
  }

  Future<void> _processImage(String imagePath) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      debugPrint('Scan: Processing image: $imagePath');

      // Extract text from image using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromImage(imagePath);

      debugPrint(
          'Scan: OCR extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'Scan: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'camera_scan',
      );

      // Dismiss loading indicator
      if (mounted) {
        setState(() => _processing = false);
      }

      // Handle validation result
      if (validation.isReject) {
        debugPrint('Scan: Receipt REJECTED - ${validation.reason}');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'camera',
          imagePath: imagePath,
        );
        // User must retake - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint('Scan: Receipt WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'camera',
          imagePath: imagePath,
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('Scan: User chose to retake photo');
          return; // Exit without processing
        }
        debugPrint('Scan: User chose to use photo anyway');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('Scan: Receipt ACCEPTED');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(imagePath);

      if (!mounted) return;

      // Show multi-item choice if we have useful data
      await _showMultiItemChoice(parsedData, attachmentPath);
    } catch (e) {
      debugPrint('Scan: Image processing error: $e');
      if (!mounted) return;

      setState(() => _processing = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _processPdf(String pdfPath) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      debugPrint('Scan: Processing PDF: $pdfPath');

      // Extract text from PDF using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromPdf(pdfPath);

      debugPrint(
          'Scan: PDF OCR extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'Scan: PDF parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'pdf_import',
      );

      // Dismiss loading indicator
      if (mounted) {
        setState(() => _processing = false);
      }

      // Handle validation result
      if (validation.isReject) {
        debugPrint('Scan: PDF REJECTED - ${validation.reason}');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: pdfPath,
        );
        // User must retake/reimport - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint('Scan: PDF WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: null, // No preview for PDF
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('Scan: User chose to re-select PDF');
          return; // Exit without processing
        }
        debugPrint('Scan: User chose to use PDF anyway');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('Scan: PDF ACCEPTED');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(pdfPath);

      if (!mounted) return;

      // Show multi-item choice if we have useful data
      await _showMultiItemChoice(parsedData, attachmentPath);
    } catch (e) {
      debugPrint('Scan: PDF processing error: $e');
      if (!mounted) return;

      setState(() => _processing = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Copy file to attachments directory and return new path
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
    debugPrint('Scan: Copied file to: $targetPath');

    return targetPath;
  }

  /// Show multi-item choice dialog if OCR data is available
  Future<void> _showMultiItemChoice(
    ReceiptScanDraft parsedData,
    String attachmentPath,
  ) async {
    final t = AppLocalizations.of(context)!;

    // Only show choice if we have merchant or purchase date
    final hasUsefulData =
        parsedData.merchant != null || parsedData.purchaseDate != null;

    if (!hasUsefulData) {
      // No useful data, go directly to single item edit
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ItemEditScreen(
            scannedData: parsedData,
            scannedFilePath: attachmentPath,
          ),
        ),
      );
      return;
    }

    setState(() => _processing = false);

    // Show choice dialog
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
      // Navigate to multi-item screen
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiItemReceiptScreen(
            scannedData: parsedData,
            receiptFilePath: attachmentPath,
          ),
        ),
      );
    } else if (choice == 'single') {
      // Navigate to single item edit screen
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ItemEditScreen(
            scannedData: parsedData,
            scannedFilePath: attachmentPath,
          ),
        ),
      );
    } else {
      // Dialog dismissed, stay on scan screen
      setState(() => _processing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
