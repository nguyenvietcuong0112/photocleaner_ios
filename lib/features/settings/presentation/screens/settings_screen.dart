import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFF7F9FC),
        border: null,
        middle: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              _SettingsItem(
                icon: CupertinoIcons.textformat_abc_dottedunderline, // Closest to translate in standard icons
                label: 'Language',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: CupertinoIcons.share,
                label: 'Share app',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: CupertinoIcons.star,
                label: 'Rate',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: CupertinoIcons.shield_fill,
                label: 'Policy',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A5568), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFFCBD5E0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
