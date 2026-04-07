import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import 'package:shopiq/app/app_localizations.dart';
import '../../core/providers.dart';
import 'package:shopiq/app/app_lock_provider.dart';

import '../../core/widgets.dart';
import '../auth/auth_screen.dart';
import 'package:shopiq/app/lock_screen.dart';

// ── Persisted dark-mode notifier ──────────────────────────────────────────────

final persistedDarkModeProvider =
    StateNotifierProvider<DarkModeNotifier, bool>((ref) => DarkModeNotifier());

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool('dark_mode') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', state);
  }
}

// ── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final language = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Shop identity card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green600, AppColors.green700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('IQ',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auth.shopName ?? AppConstants.appName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  if (auth.ownerName != null && auth.ownerName!.isNotEmpty)
                    Text(auth.ownerName!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  if (auth.ownerPhone != null)
                    Text('+91 ${auth.ownerPhone}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('v1.0.0',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionLabel(label: l.appearance),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            iconColor: AppColors.blue600,
            iconBg: AppColors.blue50,
            title: l.darkMode,
            subtitle: isDark ? l.darkModeOn : l.darkModeOff,
            trailing: Switch(
              value: isDark,
              activeThumbColor: AppColors.green600,
              onChanged: (_) => ref.read(darkModeProvider.notifier).state = !isDark,
            ),
          ),
          const SizedBox(height: 8),

          // ── Language ─────────────────────────────────────────────────────
          _SectionLabel(label: l.languageLabel),
          _LanguageTile(
            selected: language,
            onChanged: (code) => ref.read(languageProvider.notifier).setLanguage(code),
          ),
          const SizedBox(height: 8),

          // ── Shop Info ────────────────────────────────────────────────────
          _SectionLabel(label: l.shopInfo),
          _SettingsTile(
            icon: Icons.store_outlined,
            iconColor: AppColors.green600,
            iconBg: AppColors.green50,
            title: l.shopName,
            subtitle: auth.shopName ?? AppConstants.defaultShopName,
            trailing: Icon(Icons.edit_outlined, size: 18, color: cs.outline),
            onTap: () => _showEditShopName(context, ref, auth.shopName),
          ),
          _SettingsTile(
            icon: Icons.local_shipping_outlined,
            iconColor: AppColors.blue600,
            iconBg: AppColors.blue50,
            title: l.suppliers,
            subtitle: language == 'hi' ? 'सप्लायर प्रबंधन' : 'Manage suppliers',
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
            onTap: () => context.push('/suppliers'),
          ),
          const SizedBox(height: 8),

          // ── Security ─────────────────────────────────────────────────────
          _SectionLabel(label: l.security),
          const _SecuritySection(),
          const SizedBox(height: 8),

          // ── Backup ───────────────────────────────────────────────────────
          _SectionLabel(label: l.backupRestore),
          _SettingsTile(
            icon: Icons.backup_outlined,
            iconColor: AppColors.green600,
            iconBg: AppColors.green50,
            title: l.backupData,
            subtitle: l.exportToStorage,
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
            onTap: () => context.push('/backup'),
          ),
          _SettingsTile(
            icon: Icons.restore_outlined,
            iconColor: AppColors.amber600,
            iconBg: AppColors.amber50,
            title: l.restore,
            subtitle: l.restoreFromBackup,
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
            onTap: () => context.push('/backup'),
          ),
          const SizedBox(height: 8),

          // ── About ────────────────────────────────────────────────────────
          _SectionLabel(label: l.about),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: cs.outline,
            iconBg: cs.surfaceContainerHighest,
            title: l.version,
            subtitle: '${AppConstants.appName} 1.0.0 (build 1)',
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: cs.outline,
            iconBg: cs.surfaceContainerHighest,
            title: l.privacyPolicy,
            trailing: Icon(Icons.open_in_new, size: 16, color: cs.outline),
          ),
          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.red600),
            label: Text(l.logout, style: const TextStyle(color: AppColors.red600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.red600),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditShopName(BuildContext context, WidgetRef ref, String? current) {
    final ctrl = TextEditingController(text: current ?? AppConstants.defaultShopName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.shopName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Shop name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('shopiq_shop_name', ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            // ✅ FIXED: actually calls authProvider.logout() which changes
            // AuthStatus → unauthenticated, GoRouter redirect fires → /login
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }
}

// ── Security Section ──────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);
    final notifier = ref.read(appLockProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;

    return Column(children: [
      // Biometric toggle — only shown if device supports it
      if (lockState.biometricAvailable)
        _SettingsTile(
          icon: Icons.fingerprint,
          iconColor: AppColors.blue600,
          iconBg: AppColors.blue50,
          title: l.biometricUnlock,
          subtitle: lockState.biometricEnabled ? l.biometricActive : (lockState.biometricAvailable ? 'Tap to enable' : 'Not available on this device'),
          trailing: Switch(
            value: lockState.biometricEnabled,
            activeThumbColor: AppColors.green600,
            onChanged: (v) async {
              if (v) {
                // Require biometric auth before enabling
                final ok = await notifier.authenticateWithBiometric();
                if (!ok) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Biometric authentication failed'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                  return;
                }
              }
              await notifier.setBiometricEnabled(v);
            },
          ),
        ),

      // PIN lock
      _SettingsTile(
        icon: Icons.lock_outline,
        iconColor: AppColors.green600,
        iconBg: AppColors.green50,
        title: lockState.pinEnabled ? l.pinActive : l.setPIN,
        subtitle: lockState.pinEnabled
            ? 'Tap to change or remove'
            : '4-digit PIN to secure the app',
        trailing: lockState.pinEnabled
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(8)),
                child: const Text('ON', style: TextStyle(color: AppColors.green600, fontSize: 11, fontWeight: FontWeight.w800)),
              )
            : Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
        onTap: () => lockState.pinEnabled
            ? _pinOptions(context, ref)
            : Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPinScreen())),
      ),

      // Auto-lock timer — only if any lock is active
      if (lockState.isSecured)
        _SettingsTile(
          icon: Icons.timer_outlined,
          iconColor: AppColors.amber600,
          iconBg: AppColors.amber50,
          title: l.autoLock,
          subtitle: lockState.autoLockEnabled
              ? 'Locks after ${lockState.autoLockMinutes} min'
              : 'Disabled',
          trailing: Switch(
            value: lockState.autoLockEnabled,
            activeThumbColor: AppColors.green600,
            onChanged: (v) => notifier.setAutoLock(v, minutes: lockState.autoLockMinutes),
          ),
        ),
    ]);
  }

  void _pinOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 20),
          const Text('PIN Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
            title: const Text('Change PIN'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPinScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.no_encryption_outlined, color: AppColors.red600),
            title: const Text('Remove PIN', style: TextStyle(color: AppColors.red600)),
            onTap: () {
              Navigator.pop(context);
              ref.read(appLockProvider.notifier).removePin();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('PIN removed. App lock disabled.'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ]),
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _LanguageTile({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: const Icon(Icons.translate, color: AppColors.amber600, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Language / भाषा', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Changes instantly', style: TextStyle(fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _LangOption(code: 'en', label: 'EN', selected: selected, onTap: onChanged),
            _LangOption(code: 'hi', label: 'हि', selected: selected, onTap: onChanged),
          ]),
        ),
      ]),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code, label, selected;
  final ValueChanged<String> onTap;
  const _LangOption({required this.code, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == code;
    return GestureDetector(
      onTap: () => onTap(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green600 : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            )),
      ),
    );
  }
}

// ── Shared tile widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.outline, letterSpacing: 0.8),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, this.subtitle, this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.outline)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}