import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/core/db/db_providers.dart';
import 'package:garantie_safe/home/home_screen.dart';
import '../storage/storage_choice_screen.dart';
import '../backup/snapshot_chooser_screen.dart';

/// First screen shown during onboarding.
/// User can either start fresh or restore from a backup.
class OnboardingStartScreen extends ConsumerStatefulWidget {
  const OnboardingStartScreen({super.key});

  @override
  ConsumerState<OnboardingStartScreen> createState() =>
      _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends ConsumerState<OnboardingStartScreen> {
  bool _restoring = false;
  bool _hasInternalBackup = false;

  @override
  void initState() {
    super.initState();
    _checkInternalBackup();
  }

  Future<void> _checkInternalBackup() async {
    final hasBackup = await BackupService.hasInternalBackup();
    if (mounted) {
      setState(() => _hasInternalBackup = hasBackup);
    }
  }

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
            FilledButton(
              onPressed: _restoring
                  ? null
                  : () {
                      // Continue with normal onboarding flow
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StorageChoiceScreen(),
                        ),
                      );
                    },
              child: Text(t.onb_start_fresh),
            ),
            const SizedBox(height: 16),
            if (_hasInternalBackup) ...[
              OutlinedButton.icon(
                onPressed: _restoring ? null : _restoreFromInternalBackup,
                icon: const Icon(Icons.restore),
                label: Text(t.onboarding_restore_from_backup),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _restoring ? null : _restoreFromFile,
              icon: const Icon(Icons.folder_open),
              label: Text(t.onboarding_restore_from_file),
            ),
            const SizedBox(height: 24),
            Text(
              t.onb_welcome_hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (_restoring) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _restoreFromInternalBackup() async {
    // Open snapshot chooser directly - no loading, immediate selection
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SnapshotChooserScreen(isOnboarding: true),
      ),
    );

    // After returning from snapshot chooser, check if restore was successful
    // If user restored and completed onboarding, they'll be at home screen
    // If they cancelled, they'll be back here
  }

  Future<void> _restoreFromFile() async {
    final t = AppLocalizations.of(context)!;

    setState(() => _restoring = true);
    ref.read(isRestoringProvider.notifier).state = true;

    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        // User cancelled
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.onb_restore_cancelled)),
        );
        setState(() => _restoring = false);
        ref.read(isRestoringProvider.notifier).state = false;
        return;
      }

      final file = result.files.single;

      // Validate extension
      if (!file.name.toLowerCase().endsWith('.gsbackup')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backup_select_valid_file),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _restoring = false);
        ref.read(isRestoringProvider.notifier).state = false;
        return;
      }

      // Create temp file for restore
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/onboarding_restore.gsbackup');

      if (file.bytes != null) {
        await tempFile.writeAsBytes(file.bytes!, flush: true);
      } else if (file.path != null) {
        await File(file.path!).copy(tempFile.path);
      } else {
        throw Exception('Unable to read backup file.');
      }

      // Perform restore
      await BackupService.restoreBackup(backupFilePath: tempFile.path);

      // Mark onboarding as done
      await Prefs.setOnboardingDone(true);

      if (!mounted) return;

      // Navigate to home screen (replace entire route)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.onb_restore_failed}: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() => _restoring = false);
    } finally {
      if (mounted) {
        ref.read(isRestoringProvider.notifier).state = false;
      }
    }
  }
}
