import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class ReceiptPhotoViewerScreen extends StatelessWidget {
  const ReceiptPhotoViewerScreen({
    super.key,
    required this.imagePath,
    this.heroTag,
  });

  final String imagePath;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final file = File(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.receipt_photo_title),
      ),
      body: Center(
        child: file.existsSync()
            ? InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: heroTag == null
                    ? Image.file(file)
                    : Hero(tag: heroTag!, child: Image.file(file)),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t.receipt_photo_missing,
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}
