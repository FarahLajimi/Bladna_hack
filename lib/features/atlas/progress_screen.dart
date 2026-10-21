import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/achievements_data.dart';
import '../../data/local_data/waste_items_data.dart';
import '../../data/local_data/world_data.dart';
import '../../domain/progression.dart';
import '../../domain/world_rules.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import '../../state/session_controller.dart';

/// Progress & achievements — every number comes from saved state.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameController>().progress;
    final name = context.select<SessionController, String>((s) => s.displayName);
    final level = Progression.levelFor(p.xp);
    final missionsDone = kMissions.where((m) => p.isMissionDone(m.id)).length;
    final revealed = WorldRules.revealedSites(p).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ActivityHeader(title: 'Progress'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(name, style: AppText.title),
                  Text('Level $level · ${Progression.titleFor(level)}', style: AppText.bodyStrong),
                  const SizedBox(height: 10),
                  ChunkyProgress(value: Progression.levelFraction(p.xp), semanticLabel: 'XP towards next level'),
                  const SizedBox(height: 4),
                  Text(
                    Progression.isMaxLevel(level) ? '${p.xp} XP · top level' : '${p.xp} XP · ${Progression.xpToNext(p.xp)} to next level',
                    style: AppText.data,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 28,
                    runSpacing: 14,
                    children: [
                      _Figure('$revealed/${kSites.length}', 'places revealed'),
                      _Figure('$missionsDone/${kMissions.length}', 'missions done'),
                      _Figure('${p.masteredItems.length}/${kWasteItems.length}', 'items learned'),
                      _Figure('${p.fieldRecords.length}', 'evidence records'),
                    ],
                  ),
                  const SectionTitle('Places'),
                  for (final s in kSites)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(WorldRules.isRevealed(p, s) ? s.name : 'Unrevealed',
                                style: AppText.bodyStrong.copyWith(
                                    color: WorldRules.isRevealed(p, s) ? AppColors.ink : AppColors.inkFaint)),
                          ),
                          Expanded(
                            child: ChunkyProgress(
                              value: WorldRules.siteProgress(p, s.id).$1 / WorldRules.siteProgress(p, s.id).$2,
                              color: AppColors.restored,
                              semanticLabel: '${s.name} missions',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${WorldRules.siteProgress(p, s.id).$1}/${WorldRules.siteProgress(p, s.id).$2}', style: AppText.data),
                        ],
                      ),
                    ),
                  const SectionTitle('Achievements'),
                  for (final a in kAchievements)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Icon(p.achievements.containsKey(a.id) ? a.icon : Icons.lock_outline_rounded,
                              color: p.achievements.containsKey(a.id) ? AppColors.action : AppColors.disabled),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: AppText.bodyStrong.copyWith(
                                        color: p.achievements.containsKey(a.id) ? AppColors.ink : AppColors.inkFaint)),
                                Text(a.description, style: AppText.small.copyWith(fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('XP and stars are game scores. They measure learning in BLADNA, not real-world environmental impact.',
                      style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.title.copyWith(fontSize: 24)),
        Text(label, style: AppText.small),
      ],
    );
  }
}
