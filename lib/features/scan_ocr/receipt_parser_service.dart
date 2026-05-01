import 'package:flutter/material.dart';

/// Draft data from OCR parsing (Phase 1: merchant + purchase date only)
class ReceiptScanDraft {
  final String? merchant;
  final DateTime? purchaseDate;
  final String rawText;
  final String? suggestedTitle;
  final String? paymentMethodCode;

  ReceiptScanDraft({
    this.merchant,
    this.purchaseDate,
    required this.rawText,
    this.suggestedTitle,
    this.paymentMethodCode,
  });
}

/// Service for parsing receipt text into structured data (Phase 1: simple heuristics)
class ReceiptParserService {
  /// Parse text and extract merchant + purchase date
  static ReceiptScanDraft parseText(String rawText, List<String> lines) {
    debugPrint('Parser: Parsing ${lines.length} lines of text');

    final merchant = _extractMerchant(lines);
    final purchaseDate = _extractPurchaseDate(rawText, lines);

    debugPrint('Parser: Merchant=$merchant, Date=$purchaseDate');

    return ReceiptScanDraft(
      merchant: merchant,
      purchaseDate: purchaseDate,
      rawText: rawText,
      suggestedTitle: merchant, // Use merchant as suggested title
    );
  }

  /// Extract merchant name from first few lines with improved noise filtering
  static String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    // Look at first 8 lines for merchant name
    final candidates = <String>[];

    for (int i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) continue;

      // Normalize line for OCR typos
      final normalized = _normalizeOcrMistakes(line);

      // Skip lines that look like phone numbers
      if (_looksLikePhoneNumber(normalized)) continue;

      // Skip lines that look like URLs or emails
      if (_looksLikeUrl(normalized) || _looksLikeEmail(normalized)) continue;

      // Skip lines that look like VAT IDs or tax numbers
      if (_looksLikeVatId(normalized)) continue;

      // Skip lines that look like addresses
      if (_looksLikeAddress(normalized)) continue;

      // Skip very long numeric codes or IBANs
      if (_looksLikeLongNumericCode(normalized) || _looksLikeIban(normalized)) {
        continue;
      }

      // Skip receipt headers and keywords
      if (_looksLikeReceiptHeader(normalized)) continue;

      // Skip city/postcode-only lines
      if (_looksLikeCityOrPostcode(normalized)) continue;

      // This looks like a plausible merchant name
      candidates.add(normalized);
    }

    // Canonicalize: prefer main brand over branch/location detail
    return _canonicalizeMerchant(candidates);
  }

  /// Normalize common OCR mistakes in merchant names
  static String _normalizeOcrMistakes(String line) {
    String result = line;

    // Collapse multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Replace leading zero in likely words (e.g., "0TTO'S" -> "OTTO'S")
    // Only replace if it makes the word more alphabetic
    result = result.replaceAllMapped(
      RegExp(r'\b0([A-Z]{2,})', caseSensitive: false),
      (match) {
        final word = match.group(1)!;
        // Only replace if word is mostly letters
        if (RegExp(r'^[A-Za-z]{2,}').hasMatch(word)) {
          return 'O$word';
        }
        return match.group(0)!;
      },
    );

    return result;
  }

  /// Canonicalize merchant name: prefer brand over branch
  static String? _canonicalizeMerchant(List<String> candidates) {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    // Compare first two candidates
    final first = candidates[0];
    final second = candidates.length > 1 ? candidates[1] : '';

    // If second line contains first line (e.g., "OTTO'S" vs "OTTO'S Cham"),
    // prefer the shorter first line (main brand)
    if (second.toLowerCase().contains(first.toLowerCase()) &&
        first.length < second.length) {
      return first;
    }

    // If first line contains second line, prefer second (it's the main brand)
    if (first.toLowerCase().contains(second.toLowerCase()) &&
        second.length < first.length) {
      return second;
    }

    // Default: return first plausible candidate
    return first;
  }

  /// Extract purchase date from text
  static DateTime? _extractPurchaseDate(String rawText, List<String> lines) {
    final now = DateTime.now();
    final candidates = <DateTime>[];

    // Common date patterns
    final patterns = [
      // dd.MM.yyyy
      RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b'),
      // dd/MM/yyyy
      RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b'),
      // dd-MM-yyyy
      RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{4})\b'),
      // yyyy-MM-dd
      RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'),
      // dd.MM.yy
      RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{2})\b'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(rawText);
      for (final match in matches) {
        try {
          DateTime? date;

          if (match.groupCount >= 3) {
            final g1 = int.tryParse(match.group(1)!);
            final g2 = int.tryParse(match.group(2)!);
            final g3 = int.tryParse(match.group(3)!);

            if (g1 == null || g2 == null || g3 == null) continue;

            // Determine date format based on pattern
            if (pattern.pattern.contains(r'\d{4}') &&
                pattern.pattern.startsWith(r'\b\(\d{4}\)')) {
              // yyyy-MM-dd
              date = DateTime(g1, g2, g3);
            } else if (g3 > 31) {
              // dd.MM.yyyy or dd/MM/yyyy or dd-MM-yyyy
              int year = g3;
              // Handle 2-digit years
              if (year < 100) {
                year += (year < 50) ? 2000 : 1900;
              }
              date = DateTime(year, g2, g1);
            } else {
              // Ambiguous, try dd.MM.yy
              int year = g3;
              if (year < 100) {
                year += (year < 50) ? 2000 : 1900;
              }
              date = DateTime(year, g2, g1);
            }

            // Skip future dates (likely not purchase dates)
            if (date.isAfter(now.add(const Duration(days: 1)))) {
              continue;
            }

            // Skip dates too far in the past (>20 years)
            if (date.isBefore(now.subtract(const Duration(days: 365 * 20)))) {
              continue;
            }

            candidates.add(date);
          }
        } catch (e) {
          // Invalid date, skip
          continue;
        }
      }
    }

    // Return most recent plausible date
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a)); // Newest first
      return candidates.first;
    }

    return null;
  }

  // Heuristic helpers

  static bool _looksLikePhoneNumber(String line) {
    // Contains +, (), -, / and multiple digits
    final phonePattern = RegExp(r'[\+\(\)\-\/\s]*\d[\+\(\)\-\/\s\d]{7,}');
    return phonePattern.hasMatch(line) && line.contains(RegExp(r'\d{3,}'));
  }

  static bool _looksLikeUrl(String line) {
    final lower = line.toLowerCase();
    return lower.contains('www.') ||
        lower.contains('http') ||
        lower.contains('.com') ||
        lower.contains('.de') ||
        lower.contains('.ch');
  }

  static bool _looksLikeEmail(String line) {
    return line.contains('@') && line.contains('.');
  }

  static bool _looksLikeVatId(String line) {
    final upper = line.toUpperCase();
    return (upper.contains('VAT') ||
            upper.contains('UST') ||
            upper.contains('MWST') ||
            upper.contains('TVA') ||
            upper.contains('UID') ||
            upper.contains('CHE-') ||
            upper.contains('CHE ')) &&
        line.contains(RegExp(r'\d'));
  }

  static bool _looksLikeAddress(String line) {
    final lower = line.toLowerCase();
    // Contains street indicators + numbers
    return (lower.contains('str') ||
            lower.contains('strasse') ||
            lower.contains('weg') ||
            lower.contains('platz') ||
            lower.contains('gasse')) &&
        line.contains(RegExp(r'\d'));
  }

  static bool _looksLikeLongNumericCode(String line) {
    // More than 12 consecutive digits
    return RegExp(r'\d{12,}').hasMatch(line);
  }

  static bool _looksLikeIban(String line) {
    // IBAN pattern or card mask (XXXX XXXX XXXX 1234)
    final upper = line.toUpperCase();
    return upper.contains('IBAN') ||
        RegExp(r'\b[A-Z]{2}\d{2}\s?\d{4}').hasMatch(upper) ||
        RegExp(r'X{4}\s?X{4}\s?X{4}').hasMatch(upper);
  }

  static bool _looksLikeReceiptHeader(String line) {
    final lower = line.toLowerCase();
    return lower.contains('kasse') ||
        lower.contains('bon') ||
        lower.contains('receipt') ||
        lower.contains('total') ||
        lower.contains('summe') ||
        lower.contains('betrag') ||
        lower.contains('quittung') ||
        lower == 'chf' ||
        lower == 'eur' ||
        lower == 'usd';
  }

  static bool _looksLikeCityOrPostcode(String line) {
    // Just a number (postcode only)
    if (RegExp(r'^\d{4,5}$').hasMatch(line.trim())) return true;

    // Common Swiss/German city patterns without street info
    final lower = line.toLowerCase();
    if (lower.length < 25 &&
        RegExp(r'^\d{4,5}\s+[a-zäöüß\s]+$', caseSensitive: false)
            .hasMatch(line)) {
      return true;
    }

    return false;
  }
}
