/// Payment method model for database persistence
class PaymentMethod {
  final int? id;
  final String code;
  final String? customLabel; // For user-defined methods
  final bool isBuiltIn;
  final bool isEnabled;
  final bool isArchived;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const PaymentMethod({
    this.id,
    required this.code,
    this.customLabel,
    required this.isBuiltIn,
    required this.isEnabled,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentMethod copyWith({
    int? id,
    String? code,
    String? customLabel,
    bool? isBuiltIn,
    bool? isEnabled,
    bool? isArchived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      code: code ?? this.code,
      customLabel: customLabel ?? this.customLabel,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'custom_label': customLabel,
      'is_built_in': isBuiltIn ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      code: map['code'] as String,
      customLabel: map['custom_label'] as String?,
      isBuiltIn: (map['is_built_in'] as int) == 1,
      isEnabled: (map['is_enabled'] as int) == 1,
      isArchived: (map['is_archived'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  @override
  String toString() {
    return 'PaymentMethod(code: $code, isBuiltIn: $isBuiltIn, isEnabled: $isEnabled, isArchived: $isArchived)';
  }
}
