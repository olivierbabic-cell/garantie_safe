class Receipt {
  final int? id;
  final String? merchant; // optional (kann vom Item kommen)
  final DateTime purchaseDate;
  final String? attachmentPath; // image/pdf
  final String? attachmentType; // 'image' | 'pdf'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Receipt({
    this.id,
    this.merchant,
    required this.purchaseDate,
    this.attachmentPath,
    this.attachmentType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'merchant': merchant,
        'purchase_date': purchaseDate.toIso8601String(),
        'attachment_path': attachmentPath,
        'attachment_type': attachmentType,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static Receipt fromMap(Map<String, dynamic> map) => Receipt(
        id: map['id'] as int?,
        merchant: (map['merchant'] as String?)?.trim(),
        purchaseDate: _safeParseDate(map['purchase_date']) ?? DateTime.now(),
        attachmentPath: (map['attachment_path'] as String?)?.trim(),
        attachmentType: (map['attachment_type'] as String?)?.trim(),
        createdAt: _safeParseDate(map['created_at']) ?? DateTime.now(),
        updatedAt: _safeParseDate(map['updated_at']) ?? DateTime.now(),
      );

  static DateTime? _safeParseDate(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input;
    final s = input.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
