import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../payments/payment_methods_screen.dart';

class StorageChoiceScreen extends StatelessWidget {
  const StorageChoiceScreen({super.key});

  Future<void> _saveChoice(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('onb_storage', value);
  }

  Future<void> _saveAndNext(BuildContext context, String value) async {
    await _saveChoice(value);
    if (!context.mounted) return; // ✅ Context erst NACH await nutzen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.storage_title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.storage_question, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.smartphone),
              label: Text(t.storage_local),
              onPressed: () => _saveAndNext(context, 'local'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud),
              label: Text(t.storage_cloud),
              onPressed: () => _saveAndNext(context, 'gdrive'), // später OAuth
            ),
            const Spacer(),
            Text(
              t.storage_footer,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
