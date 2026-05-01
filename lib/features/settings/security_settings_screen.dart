import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import '../../core/prefs.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _loading = true;
  bool _appLockEnabled = true;
  bool _deviceHasSecureLock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await Prefs.getAppLockEnabled();

    // Check if device has biometrics or PIN/password
    bool hasSecureLock = false;
    try {
      final auth = LocalAuthentication();
      hasSecureLock =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking device lock: $e');
    }

    if (!mounted) return;
    setState(() {
      _appLockEnabled = enabled;
      _deviceHasSecureLock = hasSecureLock;
      _loading = false;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    final t = AppLocalizations.of(context)!;
    if (value && !_deviceHasSecureLock) {
      // Cannot enable if device has no secure lock
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.security_no_device_lock),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await Prefs.setAppLockEnabled(value);
    setState(() => _appLockEnabled = value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? t.security_lock_enabled : t.security_lock_disabled,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.security_screen_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.security_screen_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.security_protect_with_lock),
            subtitle: Text(
              _deviceHasSecureLock
                  ? t.security_requires_biometric
                  : t.security_no_lock_configured,
            ),
            value: _appLockEnabled,
            onChanged: _deviceHasSecureLock ? _toggleAppLock : null,
          ),
          const Divider(),
          if (!_deviceHasSecureLock)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.security_enable_lock_info,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
