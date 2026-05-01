import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

/// Result of text extraction from image or PDF
class ReceiptTextExtractionResult {
  final String rawText;
  final List<String> lines;
  final String sourceType; // "image" | "pdf"
  final String filePath;
  final int imageWidth;
  final int imageHeight;
  final double textCoveragePercent; // Percentage of image covered by text
  final double averageConfidence; // OCR confidence (0-1)
  final List<Rect> textBoundingBoxes; // Bounding boxes of all text blocks
  final List<List<Point<int>>>
      cornerPoints; // Corner points for each text block (for tilt detection)

  ReceiptTextExtractionResult({
    required this.rawText,
    required this.lines,
    required this.sourceType,
    required this.filePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.textCoveragePercent,
    required this.averageConfidence,
    required this.textBoundingBoxes,
    required this.cornerPoints,
  });
}

/// Service for extracting text from receipt images and PDFs (fully offline/local)
class ReceiptTextExtractionService {
  /// Extract text from image file using Google ML Kit (offline)
  static Future<ReceiptTextExtractionResult> extractFromImage(
      String imagePath) async {
    debugPrint('OCR: Extracting text from image: $imagePath');

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final lines =
          rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();

      // Get image dimensions
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(imageBytes);
      final imageWidth = image.width;
      final imageHeight = image.height;
      final imageArea = imageWidth * imageHeight;

      debugPrint('OCR: Image dimensions: ${imageWidth}x$imageHeight');

      // Calculate text bounding boxes, corner points, and coverage
      final List<Rect> boundingBoxes = [];
      final List<List<Point<int>>> corners = [];

      for (final block in recognizedText.blocks) {
        boundingBoxes.add(block.boundingBox);
        corners.add(block.cornerPoints);
      }

      // Calculate total text area (union of bounding boxes)
      double textArea = 0;
      if (boundingBoxes.isNotEmpty) {
        // Calculate coverage using bounding box area
        for (final box in boundingBoxes) {
          textArea += box.width * box.height;
        }
      }

      final textCoveragePercent =
          imageArea > 0 ? (textArea / imageArea) * 100 : 0.0;

      // Use a simple heuristic for confidence: longer text = better quality
      // Real blur detection would require image processing
      final averageConfidence =
          rawText.length > 100 ? 0.8 : (rawText.length > 50 ? 0.5 : 0.3);

      debugPrint('OCR: Extracted ${lines.length} lines from image');
      debugPrint(
          'OCR: Text coverage: ${textCoveragePercent.toStringAsFixed(2)}%');
      debugPrint(
          'OCR: Estimated confidence: ${averageConfidence.toStringAsFixed(2)}');

      return ReceiptTextExtractionResult(
        rawText: rawText,
        lines: lines,
        sourceType: 'image',
        filePath: imagePath,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        textCoveragePercent: textCoveragePercent.toDouble(),
        averageConfidence: averageConfidence,
        textBoundingBoxes: boundingBoxes,
        cornerPoints: corners,
      );
    } catch (e) {
      debugPrint('OCR: Error extracting from image: $e');
      rethrow;
    } finally {
      textRecognizer.close();
    }
  }

  /// Extract text from PDF file (offline)
  /// Rasterizes PDF and uses OCR (Phase 1: supports scanned/image-based PDFs)
  static Future<ReceiptTextExtractionResult> extractFromPdf(
      String pdfPath) async {
    debugPrint('OCR: Extracting text from PDF: $pdfPath');

    try {
      // Phase 1: Rasterize PDF and OCR
      // Note: Direct text extraction from digital PDFs would require additional packages
      return await _extractFromPdfViaOcr(pdfPath);
    } catch (e) {
      debugPrint('OCR: Error extracting from PDF: $e');
      rethrow;
    }
  }

  /// Rasterize PDF page to image and run OCR (for scanned/image-based PDFs)
  static Future<ReceiptTextExtractionResult> _extractFromPdfViaOcr(
      String pdfPath) async {
    try {
      // Read PDF and rasterize first page using Printing.raster
      final pdfBytes = await File(pdfPath).readAsBytes();

      // Rasterize the first page at 2x resolution for better OCR
      await for (final page in Printing.raster(pdfBytes, dpi: 200)) {
        // Only process first page (Phase 1)
        final imageBytes = await page.toPng();

        // Save to temp file for OCR
        final tempDir = Directory.systemTemp;
        final tempImagePath =
            '${tempDir.path}/pdf_ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png';
        final tempFile = File(tempImagePath);
        await tempFile.writeAsBytes(imageBytes);

        debugPrint('OCR: Rasterized PDF page to temp image: $tempImagePath');

        // Run OCR on the rasterized image
        final ocrResult = await extractFromImage(tempImagePath);

        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('OCR: Failed to delete temp file: $e');
        }

        // Return result with original PDF path
        return ReceiptTextExtractionResult(
          rawText: ocrResult.rawText,
          lines: ocrResult.lines,
          sourceType: 'pdf',
          filePath: pdfPath,
          imageWidth: ocrResult.imageWidth,
          imageHeight: ocrResult.imageHeight,
          textCoveragePercent: ocrResult.textCoveragePercent,
          averageConfidence: ocrResult.averageConfidence,
          textBoundingBoxes: ocrResult.textBoundingBoxes,
          cornerPoints: ocrResult.cornerPoints,
        );
      }

      throw Exception('PDF has no pages');
    } catch (e) {
      debugPrint('OCR: PDF OCR extraction failed: $e');
      rethrow;
    }
  }
}
