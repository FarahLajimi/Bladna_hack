import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/dataset_store.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/brand.dart';
import '../../state/game_controller.dart';
import '../../state/session_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your progress stays on this phone. When you come back — as a guest or with an account on this device — it will still be here. '
          'Nothing is synced to other devices in this version.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final session = context.read<SessionController>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    await session.signOut();
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all progress?'),
        content: const Text(
          'XP, missions, revealed places, achievements, the journal, annotations and field-evidence photos on this phone will be deleted. '
          'Settings and your sign-in stay. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep everything')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.gentleError),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final game = context.read<GameController>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    await game.resetProgress();
    await DatasetStore.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final session = context.watch<SessionController>();
    final s = game.settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ActivityHeader(title: 'Settings & account'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const SectionTitle('Account'),
                  Text(session.displayName, style: AppText.subheading),
                  Text(
                    session.isGuest
                        ? 'Guest profile — stored on this phone only. No account, nothing synced.'
                        : 'Signed in as ${session.email ?? ''} via ${session.auth.providerName}. Progress is still stored locally in this version.',
                    style: AppText.small,
                  ),
                  if (!session.auth.isConfigured)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Account sign-in is not configured in this build (see docs/FIREBASE_SETUP.md).',
                        style: AppText.small.copyWith(color: AppColors.actionDeep),
                      ),
                    ),
                  const SizedBox(height: 10),
                  BladnaButton(label: 'Sign out', icon: Icons.logout_rounded, style: BladnaButtonStyle.quiet, onPressed: () => _signOut(context)),
                  const SectionTitle('Preferences'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Haptic feedback', style: AppText.bodyStrong),
                    value: s.haptics,
                    onChanged: (v) => game.updateSettings(s.copyWith(haptics: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Reduce motion', style: AppText.bodyStrong),
                    subtitle: Text('No pulsing pins or camera flights. The system setting is respected too.', style: AppText.small),
                    value: s.reduceMotion,
                    onChanged: (v) => game.updateSettings(s.copyWith(reduceMotion: v)),
                  ),
                  const SectionTitle('What is real, what is game'),
                  Text(
                    '• Places, coordinates and facts come from the sources below; each fact shows its confidence (official, documented, reported, approximate).\n'
                    '• Borj Chakir is drawn as an approximate area around a locality coordinate — not a surveyed landfill boundary.\n'
                    '• Stars, XP, revealed places and explored areas are game progress, not real-world environmental improvement.\n'
                    '• Map annotations are positions you tapped yourself; field-evidence records are manual labels. No GPS is ever read.\n'
                    '• No AI model is installed. Nothing is predicted; nothing is uploaded.',
                    style: AppText.bodyText,
                  ),
                  const SectionTitle('Needs internet'),
                  Text('Satellite, street and Sentinel-2 imagery tiles. Everything else works offline.', style: AppText.bodyText),
                  const SectionTitle('Data sources'),
                  Text(
                    'Ramsar Information Sheet 1712 (Sebkhet Sejoumi) · Wikipedia (Lake of Tunis, Medina of Tunis, Al-Zaytuna Mosque) · '
                    'Nawaat 2015 (Borj Chakir landfill) · satellites.pro (Borj Chakir locality coordinate).\n\n'
                    'Imagery: Esri World Imagery (Esri, Maxar, Earthstar Geographics, and the GIS User Community); '
                    'EOxCloudless Sentinel-2 by EOX IT Services GmbH, contains modified Copernicus Sentinel data (2016 CC BY 4.0; 2024 CC BY-NC-SA 4.0); '
                    'map data © OpenStreetMap contributors.\n\n'
                    'Fonts: Space Grotesk, Inter, IBM Plex Mono (SIL Open Font License 1.1).',
                    style: AppText.small,
                  ),
                  const SectionTitle('Danger zone'),
                  BladnaButton(label: 'Erase all progress', icon: Icons.delete_forever_outlined, style: BladnaButtonStyle.quiet, onPressed: () => _reset(context)),
                  const SizedBox(height: 28),
                  const Center(child: BladnaLockup(markSize: 34)),
                  const SizedBox(height: 8),
                  Center(child: Text('Version 0.3 · GREEN HACKATHON 2026 prototype', style: AppText.data)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
