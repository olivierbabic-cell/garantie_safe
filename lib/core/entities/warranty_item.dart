class WarrantyItem {
  final int? id;
  final String title;
  final String merchant;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String? paymentMethod;

  // Attachment
  final String? attachmentPath;
  final String? attachmentType; // 'image' | 'pdf'

  final String? notes;
  final String? category; // DB-code (z.B. electronics)

  const WarrantyItem({
    this.id,
    required this.title,
    required this.merchant,
    required this.purchaseDate,
    this.expiryDate,
    this.paymentMethod,
    this.attachmentPath,
    this.attachmentType,
    this.notes,
    this.category,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title.trim(),
        'merchant': merchant.trim(),
        'purchase_date': purchaseDate.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'payment_method': paymentMethod,
        'attachment_path': attachmentPath,
        'attachment_type': attachmentType,
        'notes': notes,
        'category': category,
      };

  static WarrantyItem fromMap(Map<String, dynamic> map) {
    return WarrantyItem(
      id: map['id'] as int?,
      title: (map['title'] as String?)?.trim() ?? '',
      merchant: (map['merchant'] as String?)?.trim() ?? '',
      purchaseDate: _parseRequiredDate(map['purchase_date']),
      expiryDate: _parseNullableDate(map['expiry_date']),
      paymentMethod: (map['payment_method'] as String?)?.trim(),
      attachmentPath: (map['attachment_path'] as String?)?.trim(),
      attachmentType: (map['attachment_type'] as String?)?.trim(),
      notes: (map['notes'] as String?)?.trim(),
      category: (map['category'] as String?)?.trim(),
    );
  }

  static DateTime _parseRequiredDate(dynamic input) {
    final s = input?.toString().trim();
    if (s == null || s.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDate(dynamic input) {
    final s = input?.toString().trim();
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
