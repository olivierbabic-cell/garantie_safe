import 'package:flutter/material.dart';
import '../payments/payment_methods_management_screen.dart';

/// Legacy payment method settings screen - redirects to new management screen
class PaymentMethodSettingsScreen extends StatelessWidget {
  const PaymentMethodSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to new comprehensive management screen
    return const PaymentMethodsManagementScreen();
  }
}
