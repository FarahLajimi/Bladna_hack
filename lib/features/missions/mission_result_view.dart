import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/achievements_data.dart';
import '../../data/local_data/world_data.dart';
import '../../domain/game_engine.dart';
import '../../domain/progression.dart';
import '../../shared/components/components.dart';

/// Shared end-of-mission view: stars, XP, what was measured/answered, what it
/// teaches, what got revealed — then straight back to the map.
class MissionResultView extends StatelessWidget {
  const MissionResultView({super.key, required this.result, this.onAgain});

  final MissionResult result;
  final VoidCallback? onAgain;

  @override
  Widget build(BuildContext context) {
    final o = result.outcome;
    final m = result.mission;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            StarRow(result.stars, size: 30),
            const SizedBox(width: 12),
            if (o.xpGained > 0) TagChip(text: '+${o.xpGained} XP', color: AppColors.action, textColor: Colors.white),
          ],
        ),
        const SizedBox(height: 12),
        Text(result.summary, style: AppText.bodyText),
        if (o.message != null) ...[const SizedBox(height: 4), Text(o.message!, style: AppText.small)],
        const SectionTitle('What this teaches'),
        Text(m.learning, style: AppText.bodyText),
        if (o.revealedSites.isNotEmpty) ...[
          const SectionTitle('Revealed on the map'),
          for (final id in o.revealedSites)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded, color: AppColors.restored),
                  const SizedBox(width: 8),
                  Expanded(child: Text(siteById(id).name, style: AppText.bodyStrong)),
                ],
              ),
            ),
        ],
        if (o.newAchievements.isNotEmpty || o.leveledUp) ...[
          const SectionTitle('Unlocked'),
          for (final a in o.newAchievements)
            Text('Achievement · ${achievementById(a)?.title ?? a}', style: AppText.bodyStrong),
          if (o.leveledUp) Text('Level ${o.levelAfter} · ${Progression.titleFor(o.levelAfter)}', style: AppText.bodyStrong),
        ],
        const SizedBox(height: 8),
        Text('Stars and XP are game scores — they track learning, not real-world impact.', style: AppText.small),
        const SizedBox(height: 20),
        BladnaButton(
          label: 'Back to the map',
          icon: Icons.map_outlined,
          style: BladnaButtonStyle.secondary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        if (onAgain != null) ...[
          const SizedBox(height: 10),
          BladnaButton(label: 'Try again', icon: Icons.replay_rounded, style: BladnaButtonStyle.quiet, onPressed: onAgain),
        ],
      ],
    );
  }
}
