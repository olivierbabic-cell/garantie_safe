import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class ScanStubScreen extends StatelessWidget {
  const ScanStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.scan_title)),
      body: Center(
        child: Text(t.scan_placeholder),
      ),
    );
  }
}
