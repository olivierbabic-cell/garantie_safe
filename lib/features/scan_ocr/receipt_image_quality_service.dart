import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'receipt_parser_service.dart';
import 'receipt_text_extraction_service.dart';

/// Validation status for document quality
enum ReceiptValidationStatus {
  /// Document is clearly readable and can be accepted
  accept,

  /// Document quality is uncertain - user should preview and decide
  warning,

  /// Technical error - file cannot be processed (deprecated: use 'error')
  reject,
}

/// Simple validation reason categories
enum ReceiptValidationReason {
  /// Document may be hard to read (text weak, blurry, far away, tilted)
  readabilityUncertain,

  /// Document appears partially visible or obscured
  partiallyVisible,

  /// Technical issue - file cannot be processed
  technicalError,
}

/// Result of document validation
class ReceiptValidationResult {
  final ReceiptValidationStatus status;
  final ReceiptValidationReason? reason;
  final String? message;
  final int textLength;
  final int wordCount;
  final int lineCount;
  final double? textCoveragePercent;
  final double? imageQualityScore;

  const ReceiptValidationResult({
    required this.status,
    this.reason,
    this.message,
    required this.textLength,
    required this.wordCount,
    required this.lineCount,
    this.textCoveragePercent,
    this.imageQualityScore,
  });

  bool get isAccept => status == ReceiptValidationStatus.accept;
  bool get isWarning => status == ReceiptValidationStatus.warning;
  bool get isReject => status == ReceiptValidationStatus.reject;
  bool get isError =>
      status == ReceiptValidationStatus.reject &&
      reason == ReceiptValidationReason.technicalError;
}

/// Service for validating document quality (receipts, invoices, warranty docs)
///
/// VALIDATION APPROACH:
/// - Detects document/paper ROI from OCR bounding boxes
/// - Runs quality checks on the document area, not entire image
/// - Evaluates readability of text on the document
/// - BLOCK only if text is completely unreadable
/// - WARNING if document area quality is concerning
/// - ACCEPT only if document ROI is readable
///
/// PDF HANDLING:
/// - PDFs are assumed high quality
/// - Only warn if OCR is extremely weak
/// - Default to ACCEPT for PDFs
class ReceiptImageQualityService {
  // HARD BLOCK thresholds (show preview but no "Use anyway" button)
  static const int _blockMinChars = 30; // Below = BLOCK
  static const int _blockMinLines = 3; // Below = BLOCK
  static const double _blockConfidence = 0.15; // Below = BLOCK (extremely poor)

  // Document ROI thresholds
  static const double _minDocumentArea = 5.0; // Below 5% = too small/distant
  static const double _goodDocumentArea = 20.0; // Above 20% = good size
  static const double _minTextDensity =
      0.3; // Text should cover 30% of document ROI

  // Quality thresholds for document ROI
  static const double _goodConfidence = 0.55; // Above = good quality
  static const double _poorConfidence = 0.45; // Below = concerning

  static const double _goodTilt = 8.0; // Below = excellent
  static const double _warningTilt = 12.0; // Above = concerning
  static const double _poorTilt = 25.0; // Above = very tilted

  static const int _warningChars = 60; // Below = limited text
  static const int _warningLines = 5; // Below = weak structure

  /// Calculates the document ROI (Region of Interest) from OCR bounding boxes
  /// Returns a Rect encompassing all text blocks, or null if no text
  static Rect? _calculateDocumentROI(List<Rect> boundingBoxes) {
    if (boundingBoxes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final box in boundingBoxes) {
      if (box.left < minX) minX = box.left;
      if (box.top < minY) minY = box.top;
      if (box.right > maxX) maxX = box.right;
      if (box.bottom > maxY) maxY = box.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculates text density within the document ROI
  /// Returns ratio of text area to document ROI area
  static double _calculateTextDensity(
    List<Rect> boundingBoxes,
    Rect documentROI,
  ) {
    if (boundingBoxes.isEmpty ||
        documentROI.width <= 0 ||
        documentROI.height <= 0) {
      return 0.0;
    }

    double textArea = 0;
    for (final box in boundingBoxes) {
      textArea += box.width * box.height;
    }

    final roiArea = documentROI.width * documentROI.height;
    return roiArea > 0 ? textArea / roiArea : 0.0;
  }

  /// Calculates the tilt/rotation angle of text blocks
  /// Returns the median angle in degrees (0 = perfectly horizontal)
  static double _calculateTiltAngle(List<List<math.Point<int>>> cornerPoints) {
    if (cornerPoints.isEmpty) return 0;

    final angles = <double>[];

    for (final corners in cornerPoints) {
      if (corners.length < 2) continue;

      // Calculate angle using top-left and top-right corners
      // Assumes corners are in order: [topLeft, topRight, bottomRight, bottomLeft]
      final p1 = corners[0];
      final p2 = corners.length > 1 ? corners[1] : corners[0];

      final dx = (p2.x - p1.x).toDouble();
      final dy = (p2.y - p1.y).toDouble();

      // Calculate angle in degrees
      final angleRad = math.atan2(dy, dx);
      final angleDeg = angleRad * 180 / math.pi;

      angles.add(angleDeg.abs());
    }

    if (angles.isEmpty) return 0;

    // Return median angle (more robust than average)
    angles.sort();
    final middle = angles.length ~/ 2;
    return angles.length.isOdd
        ? angles[middle]
        : (angles[middle - 1] + angles[middle]) / 2;
  }

  /// Validates document quality using document ROI-based analysis
  ///
  /// APPROACH:
  /// 1. Detect document/paper ROI from OCR bounding boxes
  /// 2. Calculate document area and text density within ROI
  /// 3. Run quality checks on document region (not full image)
  /// 4. For PDFs: lenient handling
  /// 5. For images: evaluate document readability
  ///    - Document area size (is it visible enough?)
  ///    - Text density in ROI (is text present on the paper?)
  ///    - OCR confidence in ROI (is text readable?)
  ///    - Tilt angle (is document straight?)
  /// 6. ACCEPT only if document ROI is readable
  ///    WARNING if document quality is concerning
  static ReceiptValidationResult validateReceipt({
    required ReceiptTextExtractionResult extractionResult,
    required ReceiptScanDraft? draft,
    required String source,
  }) {
    final rawText = extractionResult.rawText;
    final cleanedText = rawText.trim();
    final textLength = cleanedText.length;
    final lines = extractionResult.lines;
    final lineCount = lines.length;
    final words =
        cleanedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;

    final fileType = extractionResult.sourceType; // "image" or "pdf"
    final isPdf = fileType == 'pdf';

    // Calculate document ROI
    final documentROI =
        _calculateDocumentROI(extractionResult.textBoundingBoxes);
    final imageArea =
        extractionResult.imageWidth * extractionResult.imageHeight;
    final documentArea = documentROI != null
        ? (documentROI.width * documentROI.height) / imageArea * 100
        : 0.0;
    final textDensity = documentROI != null
        ? _calculateTextDensity(extractionResult.textBoundingBoxes, documentROI)
        : 0.0;

    final confidence = extractionResult.averageConfidence;
    final tiltAngle = _calculateTiltAngle(extractionResult.cornerPoints);

    // Debug logging with ROI details
    debugPrint('=== Document Validation [$source] ===');
    debugPrint('File type: $fileType');
    debugPrint(
        'Image size: ${extractionResult.imageWidth}x${extractionResult.imageHeight}');
    if (documentROI != null) {
      debugPrint(
          'Document ROI: ${documentROI.left.toInt()},${documentROI.top.toInt()} - ${documentROI.right.toInt()},${documentROI.bottom.toInt()}');
      debugPrint('Document area: ${documentArea.toStringAsFixed(1)}% of image');
      debugPrint(
          'Text density in ROI: ${(textDensity * 100).toStringAsFixed(1)}%');
    } else {
      debugPrint('Document ROI: not detected');
    }
    debugPrint('OCR confidence: ${confidence.toStringAsFixed(2)}');
    debugPrint('Text: $textLength chars, $wordCount words, $lineCount lines');
    debugPrint('Tilt: ${tiltAngle.toStringAsFixed(1)}°');
    debugPrint('Date detected: ${draft?.purchaseDate != null}');

    // ============================================================
    // STEP 1: HARD BLOCK CHECK
    // Block if image contains no usable text
    // ============================================================

    final hardBlock = textLength < _blockMinChars ||
        lineCount < _blockMinLines ||
        (!isPdf && confidence < _blockConfidence);

    if (hardBlock) {
      debugPrint('BLOCK: No readable text');
      debugPrint('  - Text: $textLength chars (need $_blockMinChars)');
      debugPrint('  - Lines: $lineCount (need $_blockMinLines)');
      debugPrint('  - Confidence: ${confidence.toStringAsFixed(2)}');
      return ReceiptValidationResult(
        status: ReceiptValidationStatus.reject,
        reason: ReceiptValidationReason.technicalError,
        message: 'No readable text found',
        textLength: textLength,
        wordCount: wordCount,
        lineCount: lineCount,
        textCoveragePercent: documentArea,
        imageQualityScore: confidence,
      );
    }

    // ============================================================
    // STEP 2: PDF HANDLING (LENIENT)
    // ============================================================

    if (isPdf) {
      if (textLength < 50) {
        debugPrint('WARNING: PDF has limited text ($textLength chars)');
        return ReceiptValidationResult(
          status: ReceiptValidationStatus.warning,
          reason: ReceiptValidationReason.readabilityUncertain,
          message: 'PDF may have limited readable text',
          textLength: textLength,
          wordCount: wordCount,
          lineCount: lineCount,
          textCoveragePercent: documentArea,
          imageQualityScore: confidence,
        );
      }
      debugPrint('ACCEPT: PDF with readable text');
      return ReceiptValidationResult(
        status: ReceiptValidationStatus.accept,
        message: 'Document is readable',
        textLength: textLength,
        wordCount: wordCount,
        lineCount: lineCount,
        textCoveragePercent: documentArea,
        imageQualityScore: confidence,
      );
    }

    // ============================================================
    // STEP 3: DOCUMENT ROI QUALITY EVALUATION FOR IMAGES
    // Focus on document area, not entire image
    // ============================================================

    final qualityIssues = <String>[];
    int concernLevel = 0; // 0 = good, 1 = minor concern, 2+ = warning

    // === DOCUMENT AREA CHECK ===
    // Is the document visible enough in the frame?
    if (documentROI == null || documentArea < _minDocumentArea) {
      qualityIssues.add('document not clearly visible in frame');
      concernLevel += 3; // Critical issue
      debugPrint('  ⚠ Document area too small or not detected');
    } else if (documentArea < _goodDocumentArea) {
      qualityIssues.add(
          'document appears small or distant (${documentArea.toStringAsFixed(1)}% of image)');
      concernLevel += 2;
      debugPrint('  ⚠ Document area: ${documentArea.toStringAsFixed(1)}%');
    }

    // === TEXT DENSITY IN DOCUMENT ROI ===
    // Is there enough text on the detected document area?
    if (textDensity < _minTextDensity) {
      qualityIssues.add(
          'limited text on document (density: ${(textDensity * 100).toStringAsFixed(0)}%)');
      concernLevel += 1;
      debugPrint(
          '  ⚠ Low text density: ${(textDensity * 100).toStringAsFixed(1)}%');
    }

    // === OCR CONFIDENCE (BLUR/READABILITY) ===
    // Is the text on the document readable?
    if (confidence < _poorConfidence) {
      qualityIssues.add(
          'text on document is blurry or unclear (confidence: ${confidence.toStringAsFixed(2)})');
      concernLevel += 2; // Blur is critical
      debugPrint('  ⚠ Poor OCR confidence: ${confidence.toStringAsFixed(2)}');
    } else if (confidence < _goodConfidence) {
      qualityIssues.add('text readability is uncertain');
      concernLevel += 1;
      debugPrint(
          '  ⚠ Moderate OCR confidence: ${confidence.toStringAsFixed(2)}');
    }

    // === TILT CHECK ===
    if (tiltAngle > _poorTilt) {
      qualityIssues
          .add('document is heavily tilted (${tiltAngle.toStringAsFixed(1)}°)');
      concernLevel += 2;
      debugPrint('  ⚠ Heavy tilt: ${tiltAngle.toStringAsFixed(1)}°');
    } else if (tiltAngle > _warningTilt) {
      qualityIssues
          .add('document appears tilted (${tiltAngle.toStringAsFixed(1)}°)');
      concernLevel += 1;
      debugPrint('  ⚠ Moderate tilt: ${tiltAngle.toStringAsFixed(1)}°');
    }

    // === TEXT QUANTITY CHECK ===
    if (textLength < _warningChars) {
      qualityIssues.add('limited text extracted ($textLength chars)');
      concernLevel += 1;
      debugPrint('  ⚠ Limited text: $textLength chars');
    }

    if (lineCount < _warningLines) {
      qualityIssues.add('weak text structure ($lineCount lines)');
      concernLevel += 1;
      debugPrint('  ⚠ Few lines: $lineCount');
    }

    // ============================================================
    // STEP 4: FINAL DECISION
    // ============================================================

    // Any concern → WARNING
    if (concernLevel > 0) {
      debugPrint('WARNING: Document quality concerns (level: $concernLevel)');
      for (final issue in qualityIssues) {
        debugPrint('  - $issue');
      }

      return ReceiptValidationResult(
        status: ReceiptValidationStatus.warning,
        reason: ReceiptValidationReason.readabilityUncertain,
        message: 'This document may be hard to read',
        textLength: textLength,
        wordCount: wordCount,
        lineCount: lineCount,
        textCoveragePercent: documentArea,
        imageQualityScore: confidence,
      );
    }

    // All signals good → ACCEPT
    debugPrint('ACCEPT: Document ROI is readable');
    debugPrint(
        '  ✓ Document area: ${documentArea.toStringAsFixed(1)}% (>${_goodDocumentArea.toStringAsFixed(1)}%)');
    debugPrint(
        '  ✓ Text density: ${(textDensity * 100).toStringAsFixed(1)}% (>${(_minTextDensity * 100).toStringAsFixed(1)}%)');
    debugPrint(
        '  ✓ OCR confidence: ${confidence.toStringAsFixed(2)} (>${_goodConfidence.toStringAsFixed(2)})');
    debugPrint(
        '  ✓ Tilt: ${tiltAngle.toStringAsFixed(1)}° (<${_goodTilt.toStringAsFixed(1)}°)');
    debugPrint('  ✓ Text: $textLength chars, $lineCount lines');

    return ReceiptValidationResult(
      status: ReceiptValidationStatus.accept,
      message: 'Document is readable',
      textLength: textLength,
      wordCount: wordCount,
      lineCount: lineCount,
      textCoveragePercent: documentArea,
      imageQualityScore: confidence,
    );
  }
}
