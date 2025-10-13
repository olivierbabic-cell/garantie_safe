import 'package:flutter/material.dart';
import 'package:garantie_safe/features/notifications/notification_settings_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final Map<String, bool> _methods = {
    'Barzahlung': false,
    'EC / Maestro / Debitkarte': false,
    'Kreditkarte (Visa/Mastercard/Amex)': false,
    'Twint': false,
    'PayPal': false,
    'Apple Pay': false,
    'Google Pay': false,
    'Rechnung / Klarna': false,
    'Geschenkkarte / Gutschein': false,
    'Finanzierung / Ratenzahlung': false,
    'Andere': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zahlungsarten auswählen')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Welche Zahlungsarten nutzt du typischerweise? '
              'Diese Vorauswahl beschleunigt das Erfassen neuer Belege.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView(
              children: _methods.keys.map((k) {
                return CheckboxListTile(
                  title: Text(k),
                  value: _methods[k],
                  onChanged: (v) => setState(() => _methods[k] = v ?? false),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Speichern'),
            onPressed: () async {
              final selected = _methods.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

              // kurze Bestätigung zeigen
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gespeichert: ${selected.join(', ')}')),
              );

              // mini-Verzögerung, damit SnackBar nicht „frisst“/überlagert
              await Future.delayed(const Duration(milliseconds: 200));
              if (!mounted) return;

              // weiter zum nächsten Screen
              Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
            ),
          ),
        ],
      ),
    );
  }
}
