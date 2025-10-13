import 'package:flutter/material.dart';
import 'package:garantie_safe/features/storage/storage_choice_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Behalte all deine Garantien im Blick – sicher, privat und unter deiner Kontrolle.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StorageChoiceScreen()),
                );
              },
              child: const Text('Los geht’s'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hinweis: Für Garantiefälle bitte immer den gesamten Kassenzettel scannen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
