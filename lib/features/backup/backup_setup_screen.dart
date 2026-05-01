import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Simplified backup setup screen - backup is now automatic and mandatory
/// This screen just continues to the next step after a brief pause
class BackupSetupScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const BackupSetupScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  State<BackupSetupScreen> createState() => _BackupSetupScreenState();
}

class _BackupSetupScreenState extends State<BackupSetupScreen> {
  @override
  void initState() {
    super.initState();
    _setupAndContinue();
  }

  Future<void> _setupAndContinue() async {
    // Wait a moment to show the screen (UX)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Backup is now automatic and mandatory - just continue
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.backup_setup_title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.backup, size: 64, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Setting up automatic backups...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Your data will be backed up automatically\nin secure app storage.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
