import 'package:flutter/material.dart';
import 'package:garantie_safe/features/payments/payment_methods_screen.dart';

class StorageChoiceScreen extends StatelessWidget {
  const StorageChoiceScreen({super.key});

  void _goNext(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speicherort wählen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wo sollen deine Daten gespeichert werden?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.smartphone),
              label: const Text('Nur auf diesem Gerät'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auswahl: Lokal (kommt später)')),
                );
                // TODO: Auswahl persistent speichern (später)
                _goNext(context);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud),
              label: const Text('In deiner Cloud (Google Drive)'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auswahl: Google Drive (kommt später)')),
                );
                // TODO: OAuth-Flow starten & Auswahl speichern (später)
                _goNext(context);
              },
            ),
            const Spacer(),
            const Text(
              'Hinweis: Du kannst das später in den Einstellungen ändern.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
