import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  String? _type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndLock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bei Rückkehr in die App erneut sperren (optional)
    if (state == AppLifecycleState.resumed) {
      _checkAndLock();
    }
  }

  Future<void> _checkAndLock() async {
    final sp = await SharedPreferences.getInstance();
    _type = sp.getString('security_type'); // 'device', 'pin', 'none'
    if (_type == 'none' || _type == null) {
      setState(() => _unlocked = true);
      return;
    }
    if (!mounted) return;
    if (_type == 'device') {
      final t = AppLocalizations.of(context)!;
      final ok = await _auth.authenticate(
        localizedReason: t.device_lock_reason,
        options:
            const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (!mounted) return;
      setState(() => _unlocked = ok);
    } else if (_type == 'pin') {
      // super simple PIN-Abfrage (als Dialog). Später schöner machen.
      final t = AppLocalizations.of(context)!;
      final pin = sp.getString('security_pin') ?? '';
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(t.pin_dialog_title),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(labelText: t.pin_label),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel)),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim() == pin),
              child: Text(t.unlock),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _unlocked = (ok ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
