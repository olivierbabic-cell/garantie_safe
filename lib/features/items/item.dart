import 'package:meta/meta.dart';

@immutable
class Item {
  final String id;

  // B2B/B2F ready
  final String vaultId; // default: "personal"

  // Core
  final String title;
  final String? merchant;

  // Dates stored as UTC millis
  final int? purchaseDateMs;

  /// Optional: derived or manual
  final int? expiryDateMs;

  /// Optional: 2/3/5 or custom years; if set and purchaseDateMs exists we can auto-calc expiry
  final int? warrantyYears;

  // Codes
  final String? categoryCode;
  final String? paymentMethodCode;

  // Notes
  final String? notes;

  // Attachment (single file for MVP)
  final String? attachmentPath; // file path in app dir
  final String? attachmentType; // "image" | "pdf"

  // Meta
  final int createdAtMs;
  final int updatedAtMs;

  const Item({
    required this.id,
    required this.vaultId,
    required this.title,
    this.merchant,
    this.purchaseDateMs,
    this.expiryDateMs,
    this.warrantyYears,
    this.categoryCode,
    this.paymentMethodCode,
    this.notes,
    this.attachmentPath,
    this.attachmentType,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  Item copyWith({
    String? id,
    String? vaultId,
    String? title,
    String? merchant,
    int? purchaseDateMs,
    int? expiryDateMs,
    int? warrantyYears,
    String? categoryCode,
    String? paymentMethodCode,
    String? notes,
    String? attachmentPath,
    String? attachmentType,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return Item(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      purchaseDateMs: purchaseDateMs ?? this.purchaseDateMs,
      expiryDateMs: expiryDateMs ?? this.expiryDateMs,
      warrantyYears: warrantyYears ?? this.warrantyYears,
      categoryCode: categoryCode ?? this.categoryCode,
      paymentMethodCode: paymentMethodCode ?? this.paymentMethodCode,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'vault_id': vaultId,
        'title': title,
        'merchant': merchant,
        'purchase_date_ms': purchaseDateMs,
        'expiry_date_ms': expiryDateMs,
        'warranty_years': warrantyYears,
        'category_code': categoryCode,
        'payment_method_code': paymentMethodCode,
        'notes': notes,
        'attachment_path': attachmentPath,
        'attachment_type': attachmentType,
        'created_at_ms': createdAtMs,
        'updated_at_ms': updatedAtMs,
      };

  static Item fromMap(Map<String, Object?> map) {
    return Item(
      id: (map['id'] as String),
      vaultId: (map['vault_id'] as String?) ?? 'personal',
      title: (map['title'] as String?) ?? '',
      merchant: map['merchant'] as String?,
      purchaseDateMs: map['purchase_date_ms'] as int?,
      expiryDateMs: map['expiry_date_ms'] as int?,
      warrantyYears: map['warranty_years'] as int?,
      categoryCode: map['category_code'] as String?,
      paymentMethodCode: map['payment_method_code'] as String?,
      notes: map['notes'] as String?,
      attachmentPath: map['attachment_path'] as String?,
      attachmentType: map['attachment_type'] as String?,
      createdAtMs: (map['created_at_ms'] as int?) ?? 0,
      updatedAtMs: (map['updated_at_ms'] as int?) ?? 0,
    );
  }
}
