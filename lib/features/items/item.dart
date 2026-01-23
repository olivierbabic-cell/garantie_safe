import 'package:meta/meta.dart';

@immutable
class Item {
  final int id;

  // B2B/B2F ready (not used in AppDb v2, but kept for future)
  final String vaultId; // default: "personal"

  // Core
  final String title;
  final String? merchant;

  // Dates stored as INTEGER timestamps (millis since epoch)
  final int purchaseDate;
  final int? expiryDate;

  // Warranty duration in years (2, 3, 5, or custom)
  final int? warrantyYears;

  // Codes
  final String? categoryCode;
  final String? paymentMethodCode;

  // Notes
  final String? notes;

  // Meta
  final int createdAt;
  final int updatedAt;

  const Item({
    required this.id,
    required this.vaultId,
    required this.title,
    this.merchant,
    required this.purchaseDate,
    this.expiryDate,
    this.warrantyYears,
    this.categoryCode,
    this.paymentMethodCode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Item copyWith({
    int? id,
    String? vaultId,
    String? title,
    String? merchant,
    int? purchaseDate,
    int? expiryDate,
    int? warrantyYears,
    String? categoryCode,
    String? paymentMethodCode,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warrantyYears: warrantyYears ?? this.warrantyYears,
      categoryCode: categoryCode ?? this.categoryCode,
      paymentMethodCode: paymentMethodCode ?? this.paymentMethodCode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'merchant': merchant,
        'category_code': categoryCode,
        'purchase_date': purchaseDate,
        'expiry_date': expiryDate,
        'warranty_years': warrantyYears,
        'payment_method_code': paymentMethodCode,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static Item fromMap(Map<String, Object?> map) {
    return Item(
      id: map['id'] as int,
      vaultId: 'personal', // not in AppDb v2
      title: (map['title'] as String?) ?? '',
      merchant: map['merchant'] as String?,
      purchaseDate: (map['purchase_date'] as int?) ?? 0,
      expiryDate: map['expiry_date'] as int?,
      warrantyYears: map['warranty_years'] as int?,
      categoryCode: map['category_code'] as String?,
      paymentMethodCode: map['payment_method_code'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as int?) ?? 0,
      updatedAt: (map['updated_at'] as int?) ?? 0,
    );
  }
}
