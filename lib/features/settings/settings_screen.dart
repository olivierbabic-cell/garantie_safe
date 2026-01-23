import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/locale_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  /// 'system' | 'de' | 'en'
  String _language = 'system';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dark = await Prefs.getDarkMode();
    final lang = await Prefs.getLanguage(); // 'de' | 'en' | null
    if (!mounted) return;
    setState(() {
      _darkMode = dark;
      _language = (lang == null || lang.isEmpty) ? 'system' : lang;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    await Prefs.setDarkMode(value);
    if (!mounted) return;
    setState(() => _darkMode = value);
  }

  Future<void> _setLanguage(String code) async {
    await LocaleController.instance.setLanguage(code);
    if (!mounted) return;
    setState(() => _language = code);
  }

  Future<void> _restartOnboarding() async {
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.restart_onboarding_title),
        content: Text(t.restart_onboarding_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.restart),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await Prefs.resetOnboarding();
    if (!mounted) return;

    // Optional: direkt starten:
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.settings_section_general,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            title: Text(t.settings_dark_mode),
            subtitle: Text(t.settings_dark_mode_sub),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          const Divider(),

          // Sprache
          ListTile(
            title: Text(t.settings_language),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (v) {
                if (v == null) return;
                _setLanguage(v);
              },
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(t.settings_language_system),
                ),
                const DropdownMenuItem(
                  value: 'de',
                  child: Text('Deutsch'),
                ),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            t.settings_section_security,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            title: Text(t.settings_restart_onboarding),
            subtitle: Text(t.settings_restart_onboarding_sub),
            trailing: const Icon(Icons.refresh),
            onTap: _restartOnboarding,
          ),
        ],
      ),
    );
  }
}
