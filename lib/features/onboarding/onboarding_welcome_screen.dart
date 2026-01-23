import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import '../storage/storage_choice_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              t.onb_welcome_headline,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const StorageChoiceScreen()),
                );
              },
              child: Text(t.onb_lets_go),
            ),
            const SizedBox(height: 24),
            Text(
              t.onb_welcome_hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
