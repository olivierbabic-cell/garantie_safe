import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Shows a modern bottom sheet to select import source (Photo or PDF)
/// Returns 'photo' or 'pdf' based on user selection, or null if dismissed
Future<String?> showImportSourcePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const ImportSourceSheet(),
  );
}

/// Modern bottom sheet for selecting import source
class ImportSourceSheet extends StatelessWidget {
  const ImportSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                t.import_source_title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                t.import_source_subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              // Photo option
              ImportSourceOption(
                icon: Icons.photo_library_outlined,
                title: t.import_photo,
                subtitle: t.import_photo_subtitle,
                accentColor: const Color(0xFF3B82F6),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              const SizedBox(height: 12),

              // PDF option
              ImportSourceOption(
                icon: Icons.picture_as_pdf_outlined,
                title: t.import_pdf,
                subtitle: t.import_pdf_subtitle,
                accentColor: const Color(0xFFEF4444),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual import source option in the sheet
class ImportSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const ImportSourceOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: accentColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
