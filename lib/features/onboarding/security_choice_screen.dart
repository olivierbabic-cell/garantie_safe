import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_settings_screen.dart';
import 'set_pin_screen.dart';

class SecurityChoiceScreen extends StatefulWidget {
  const SecurityChoiceScreen({super.key});

  @override
  State<SecurityChoiceScreen> createState() => _SecurityChoiceScreenState();
}

class _SecurityChoiceScreenState extends State<SecurityChoiceScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final can = await auth.canCheckBiometrics;
    if (!mounted) return;
    setState(() => _canCheckBiometrics = can);
  }

  Future<void> _saveChoiceAndNext(String type, {String? pin}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('security_type', type);
    if (pin != null) await sp.setString('security_pin', pin);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  Future<void> _setPinProtection() async {
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SetPinScreen()),
    );
    if (pin == null) return;
    await _saveChoiceAndNext('pin', pin: pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.pin_saved)),
    );
  }

  /// ✅ Gerätesperre: erlaubt Face/Touch **oder** Geräte-PIN/Pattern als Fallback.
  Future<void> _useDeviceLock() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ok = await auth.authenticate(
        localizedReason: t.device_lock_reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // <— wichtig: auch Geräte-PIN erlaubt
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        await _saveChoiceAndNext('device'); // wir merken „device“ als Typ
        messenger.showSnackBar(SnackBar(content: Text(t.device_lock_enabled)));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.device_lock_error)));
    }
  }

  Future<void> _setNoProtection() async {
    await _saveChoiceAndNext('none');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.security_title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.security_question, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock),
              label: Text(t.security_pin),
              onPressed: _setPinProtection,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: Text(t.security_device_lock), // Face/Touch/Code des Geräts
              onPressed: _useDeviceLock,
            ),
            if (_canCheckBiometrics) const SizedBox(height: 4),
            if (_canCheckBiometrics)
              Text(
                t.security_device_lock_hint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: Text(t.security_none),
              onPressed: _setNoProtection,
            ),
            const Spacer(),
            Text(
              t.security_footer,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
