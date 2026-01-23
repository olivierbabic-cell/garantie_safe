import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/prefs.dart';

// ⬇️ nach Payments geht es zu SecurityChoice
import '../onboarding/security_choice_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Stabile Codes (werden gespeichert)
  static const List<String> _codes = <String>[
    'cash',
    'debit',
    'credit',
    'twint',
    'paypal',
    'applepay',
    'googlepay',
    'invoice',
    'giftcard',
    'financing',
    'other',
  ];

  final Map<String, bool> _selected = <String, bool>{
    for (final c in _codes) c: false,
  };

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await Prefs.getPaymentMethods(); // List<String> codes
    if (!mounted) return;

    for (final c in _codes) {
      _selected[c] = existing.contains(c);
    }

    setState(() => _loaded = true);
  }

  String _labelFor(AppLocalizations t, String code) {
    switch (code) {
      case 'cash':
        return t.pm_cash;
      case 'debit':
        return t.pm_debit;
      case 'credit':
        return t.pm_credit;
      case 'twint':
        return t.pm_twint;
      case 'paypal':
        return t.pm_paypal;
      case 'applepay':
        return t.pm_applepay;
      case 'googlepay':
        return t.pm_googlepay;
      case 'invoice':
        return t.pm_invoice;
      case 'giftcard':
        return t.pm_giftcard;
      case 'financing':
        return t.pm_financing;
      case 'other':
        return t.pm_other;
      default:
        return code;
    }
  }

  Future<void> _saveAndContinue() async {
    final selectedCodes =
        _selected.entries.where((e) => e.value).map((e) => e.key).toList();

    await Prefs.setPaymentMethods(selectedCodes);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SecurityChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.payments_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.payments_intro,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: _codes.map((code) {
                      return CheckboxListTile(
                        title: Text(_labelFor(t, code)),
                        value: _selected[code] ?? false,
                        onChanged: (v) =>
                            setState(() => _selected[code] = v ?? false),
                      );
                    }).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(t.payments_save),
              onPressed: _saveAndContinue,
            ),
          ),
        ],
      ),
    );
  }
}
