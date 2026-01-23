import 'package:flutter/foundation.dart';

enum AttachmentType { image, pdf, other }

AttachmentType attachmentTypeFromString(String v) {
  switch (v) {
    case 'image':
      return AttachmentType.image;
    case 'pdf':
      return AttachmentType.pdf;
    default:
      return AttachmentType.other;
  }
}

String attachmentTypeToString(AttachmentType t) {
  switch (t) {
    case AttachmentType.image:
      return 'image';
    case AttachmentType.pdf:
      return 'pdf';
    case AttachmentType.other:
      return 'other';
  }
}

@immutable
class ItemAttachment {
  const ItemAttachment({
    this.id,
    required this.itemId,
    required this.path,
    required this.type,
    required this.createdAt,
    required this.sortOrder,
    this.originalName,
  });

  final int? id;
  final int itemId;

  /// Lokaler Pfad zur Datei (image/pdf)
  final String path;

  final AttachmentType type;

  /// Optional: Dateiname wie er beim Import hiess
  final String? originalName;

  /// Anzeige-Reihenfolge (0..n)
  final int sortOrder;

  final DateTime createdAt;

  static const table = 'item_attachments';

  static const cId = 'id';
  static const cItemId = 'item_id';
  static const cPath = 'path';
  static const cType = 'type';
  static const cOriginalName = 'original_name';
  static const cSortOrder = 'sort_order';
  static const cCreatedAt = 'created_at';

  Map<String, Object?> toMap() => {
        cId: id,
        cItemId: itemId,
        cPath: path,
        cType: attachmentTypeToString(type),
        cOriginalName: originalName,
        cSortOrder: sortOrder,
        cCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
      };

  static ItemAttachment fromMap(Map<String, Object?> m) {
    DateTime dt(String key) =>
        DateTime.fromMillisecondsSinceEpoch(m[key] as int, isUtc: true)
            .toLocal();

    return ItemAttachment(
      id: m[cId] as int?,
      itemId: m[cItemId] as int,
      path: m[cPath] as String,
      type: attachmentTypeFromString(m[cType] as String),
      originalName: m[cOriginalName] as String?,
      sortOrder: (m[cSortOrder] as int?) ?? 0,
      createdAt: dt(cCreatedAt),
    );
  }
}
