import 'package:flutter/widgets.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class PaymentMethods {
  static const List<String> codes = <String>[
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

  static String label(BuildContext context, String code) {
    final t = AppLocalizations.of(context)!;
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
}
