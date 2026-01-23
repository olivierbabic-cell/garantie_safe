import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  void _save() {
    final t = AppLocalizations.of(context)!;
    final p1 = _pin1.text.trim();
    final p2 = _pin2.text.trim();

    if (p1.length != 4 || p2.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pin_invalid)),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pin_mismatch)),
      );
      return;
    }
    Navigator.of(context).pop<String>(p1); // PIN an Aufrufer zurückgeben
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.pin_setup_title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.pin_setup_intro, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _pin1,
              focusNode: _f1,
              maxLength: 4,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.pin_label),
              onSubmitted: (_) => _f2.requestFocus(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pin2,
              focusNode: _f2,
              maxLength: 4,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.pin_label_confirm),
              onSubmitted: (_) => _save(),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(t.save),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
