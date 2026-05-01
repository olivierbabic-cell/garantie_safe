import 'package:flutter/material.dart';
import '../backup/backup_setup_screen.dart';
import '../payments/payment_methods_screen.dart';

class StorageChoiceScreen extends StatefulWidget {
  const StorageChoiceScreen({super.key});

  @override
  State<StorageChoiceScreen> createState() => _StorageChoiceScreenState();
}

class _StorageChoiceScreenState extends State<StorageChoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return BackupSetupScreen(
      isOnboarding: true,
      onComplete: () {
        // Navigate to next step (payments)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
        );
      },
    );
  }
}
