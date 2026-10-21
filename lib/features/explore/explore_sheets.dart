import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/world.dart';
import '../../domain/progression.dart';
import '../../domain/world_rules.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import '../../state/session_controller.dart';
import '../atlas/discoveries_screen.dart';
import '../atlas/progress_screen.dart';
import '../settings/settings_screen.dart';

/// Map layer state chosen in the layer menu.
class LayerState {
  const LayerState({
    this.base = 'esri',
    this.compare = false,
    this.investigation = true,
    this.annotations = true,
  });

  final String base;

  /// Sentinel-2 2016 ↔ 2024 swipe. Only offered between the two comparable mosaics.
  final bool compare;
  final bool investigation;
  final bool annotations;

  LayerState copyWith({String? base, bool? compare, bool? investigation, bool? annotations}) => LayerState(
        base: base ?? this.base,
        compare: compare ?? this.compare,
        investigation: investigation ?? this.investigation,
        annotations: annotations ?? this.annotations,
      );
}

Future<LayerState?> showLayerMenu(BuildContext context, LayerState current) {
  return showModalBottomSheet<LayerState>(
    context: context,
    backgroundColor: AppColors.limestone,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _LayerMenu(initial: current),
  );
}

class _LayerMenu extends StatefulWidget {
  const _LayerMenu({required this.initial});
  final LayerState initial;

  @override
  State<_LayerMenu> createState() => _LayerMenuState();
}

class _LayerMenuState extends State<_LayerMenu> {
  late LayerState _s = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Map layers', style: AppText.heading)),
                TextButton(onPressed: () => Navigator.of(context).pop(_s), child: const Text('Done')),
              ],
            ),
            const SectionTitle('Base map'),
            for (final b in kBasemaps)
              _Choice(
                selected: !_s.compare && _s.base == b.id,
                title: b.label,
                detail: b.detail,
                onTap: () => setState(() => _s = _s.copyWith(base: b.id, compare: false)),
              ),
            _Choice(
              selected: _s.compare,
              title: 'Compare 2016 ↔ 2024',
              detail:
                  'Swipe between the two Sentinel-2 cloudless mosaics — same sensor, provider and 10 m pixels. Differences can also come from season or mosaic processing.',
              onTap: () => setState(() => _s = _s.copyWith(compare: true)),
            ),
            const SectionTitle('Overlays'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _s.investigation,
              onChanged: (v) => setState(() => _s = _s.copyWith(investigation: v)),
              title: Text('Investigation layer', style: AppText.bodyStrong),
              subtitle: Text('Your trail between places, explored areas, approximate zones.', style: AppText.small),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _s.annotations,
              onChanged: (v) => setState(() => _s = _s.copyWith(annotations: v)),
              title: Text('My annotations', style: AppText.bodyStrong),
              subtitle: Text('Pins you placed yourself (not GPS, not verified).', style: AppText.small),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule_rounded, size: 18, color: AppColors.inkFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Land-cover map (ESA WorldCover, 10 m): planned. Not connected in this build — no land-cover colors are shown or invented.',
                    style: AppText.small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.selected, required this.title, required this.detail, required this.onTap});

  final bool selected;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.action : AppColors.inkFaint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyStrong),
                    Text(detail, style: AppText.small.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search places and missions. Unrevealed places stay hidden.
Future<RealSite?> showPlaceSearch(BuildContext context) {
  return showModalBottomSheet<RealSite>(
    context: context,
    backgroundColor: AppColors.limestone,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => const _SearchSheet(),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameController>().progress;
    final q = _q.trim().toLowerCase();
    final results = kSites.where((s) {
      if (q.isEmpty) return true;
      if (!WorldRules.isRevealed(p, s)) return false;
      final hay = [s.name, s.arabicName, s.kind, ...missionsAt(s.id).map((m) => m.title)].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search places and missions',
                  filled: true,
                  fillColor: AppColors.paper,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mineral)),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                children: [
                  for (final s in results)
                    ListTile(
                      leading: Icon(
                        WorldRules.isRevealed(p, s)
                            ? (WorldRules.siteComplete(p, s.id) ? Icons.check_circle_rounded : Icons.place_outlined)
                            : Icons.help_outline_rounded,
                        color: WorldRules.isRevealed(p, s) ? AppColors.ink : AppColors.inkFaint,
                      ),
                      title: Text(WorldRules.isRevealed(p, s) ? s.name : 'Unrevealed place', style: AppText.bodyStrong),
                      subtitle: Text(WorldRules.isRevealed(p, s) ? s.kind : s.revealHint, style: AppText.small),
                      onTap: () => Navigator.of(context).pop(s),
                    ),
                  if (results.isEmpty)
                    const EmptyState(title: 'Nothing found', message: 'Only revealed places are searchable.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The compact menu: discoveries, progress, settings. Always returns to the map.
Future<void> showAtlasMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.limestone,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => const _AtlasMenu(),
  );
}

class _AtlasMenu extends StatelessWidget {
  const _AtlasMenu();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameController>().progress;
    final session = context.watch<SessionController>();
    final level = Progression.levelFor(p.xp);
    final done = kMissions.where((m) => p.isMissionDone(m.id)).length;
    void open(Widget page) {
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute<void>(builder: (_) => page));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.displayName, style: AppText.heading),
            Text(session.isGuest ? 'Guest · progress saved on this phone only' : (session.email ?? 'Signed in'),
                style: AppText.small),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Lv $level', style: AppText.data.copyWith(color: AppColors.ink, fontSize: 14)),
                const SizedBox(width: 8),
                Text(Progression.titleFor(level), style: AppText.bodyStrong),
                const Spacer(),
                Text('$done/${kMissions.length} missions', style: AppText.data),
              ],
            ),
            const SizedBox(height: 6),
            ChunkyProgress(value: Progression.levelFraction(p.xp), semanticLabel: 'XP towards next level'),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text('My discoveries', style: AppText.bodyStrong),
              subtitle: Text('Journal, field evidence, map annotations', style: AppText.small),
              onTap: () => open(const DiscoveriesScreen()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.military_tech_outlined),
              title: Text('Progress & achievements', style: AppText.bodyStrong),
              onTap: () => open(const ProgressScreen()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: Text('Settings, account & sources', style: AppText.bodyStrong),
              onTap: () => open(const SettingsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
