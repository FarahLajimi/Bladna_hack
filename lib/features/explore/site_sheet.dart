import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/world.dart';
import '../../domain/world_rules.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';

Color confidenceColor(Confidence c) => switch (c) {
      Confidence.official => AppColors.secondary,
      Confidence.documented => AppColors.midnightSoft,
      Confidence.reported => AppColors.warning,
      Confidence.approximate => AppColors.actionDeep,
      Confidence.educational => AppColors.inkFaint,
    };

/// The contextual panel for a selected place. The map stays visible above it.
class SiteSheet extends StatelessWidget {
  const SiteSheet({
    super.key,
    required this.site,
    required this.onClose,
    required this.onStart,
    required this.expanded,
    required this.onToggle,
  });

  final RealSite site;
  final VoidCallback onClose;
  final ValueChanged<Mission> onStart;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final p = game.progress;
    final revealed = WorldRules.isRevealed(p, site);
    final missions = missionsAt(site.id);
    final (done, total) = WorldRules.siteProgress(p, site.id);

    if (!revealed) {
      return _Shell(
        onClose: onClose,
        onToggle: onToggle,
        header: _Header(title: 'Unrevealed place', subtitle: 'A spatial clue — not investigated yet', trailing: null),
        children: [
          Text(site.revealHint, style: AppText.bodyText),
          const SizedBox(height: 8),
          Text('Places are revealed by completing missions elsewhere on the map.', style: AppText.small),
        ],
      );
    }

    final next = missions.where((m) => WorldRules.stateOf(p, m) == MissionState.available).toList();
    return _Shell(
      onClose: onClose,
      onToggle: onToggle,
      header: _Header(
        title: site.name,
        subtitle: '${site.arabicName}  ·  ${site.kind}',
        trailing: TagChip(
          text: '$done/$total',
          color: done == total ? AppColors.restored : AppColors.mineral,
          textColor: done == total ? Colors.white : AppColors.ink,
          icon: done == total ? Icons.check_rounded : Icons.flag_outlined,
        ),
      ),
      children: [
        if (next.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BladnaButton(
              label: 'Investigate: ${next.first.title}',
              icon: Icons.play_arrow_rounded,
              onPressed: () => onStart(next.first),
            ),
          ),
        Text('WHAT YOU\'RE LOOKING AT', style: AppText.label),
        const SizedBox(height: 4),
        Text(site.lookingAt, style: AppText.bodyText),
        if (expanded) ...[
          const SizedBox(height: 12),
          Text('WHY IT MATTERS', style: AppText.label),
          const SizedBox(height: 4),
          Text(site.whyItMatters, style: AppText.bodyText),
          const SizedBox(height: 12),
          Text('EVIDENCE', style: AppText.label),
          const SizedBox(height: 6),
          for (final e in site.evidence)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: confidenceColor(e.confidence), shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '${e.text} ', style: AppText.small.copyWith(color: AppColors.ink)),
                      TextSpan(text: '${e.confidence.label} · ${e.source}', style: AppText.data.copyWith(fontSize: 11)),
                    ])),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 6),
        Text('MISSIONS HERE', style: AppText.label),
        const SizedBox(height: 4),
        for (final m in missions) _MissionRow(mission: m, onStart: () => onStart(m)),
        if (!expanded)
          TextButton.icon(
            onPressed: onToggle,
            icon: const Icon(Icons.expand_less_rounded),
            label: const Text('Why it matters & evidence'),
          ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, required this.onStart});

  final Mission mission;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameController>().progress;
    final state = WorldRules.stateOf(p, mission);
    final stars = p.starsOf(mission.id);
    final locked = state == MissionState.locked;
    final icon = switch (mission.type) {
      MissionType.sorting => Icons.recycling_rounded,
      MissionType.digitize => Icons.polyline_outlined,
      MissionType.measure => Icons.straighten_rounded,
      MissionType.timeMachine => Icons.compare_rounded,
      MissionType.landCover => Icons.layers_outlined,
      MissionType.quiz => Icons.psychology_alt_outlined,
      MissionType.fieldEvidence => Icons.photo_camera_outlined,
    };
    final requirement = mission.requires.isEmpty ? '' : 'After "${missionById(mission.requires.first)?.title ?? ''}"';
    return Semantics(
      button: !locked,
      label: '${mission.title}. ${locked ? 'Locked. $requirement' : (stars > 0 ? '$stars of 3 stars' : 'Available')}',
      excludeSemantics: true,
      child: InkWell(
        onTap: locked ? null : onStart,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: locked ? AppColors.mineral : (stars > 0 ? AppColors.restored : AppColors.midnight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(locked ? Icons.lock_outline_rounded : icon, size: 18, color: locked ? AppColors.inkFaint : Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.title, style: AppText.bodyStrong.copyWith(color: locked ? AppColors.inkFaint : AppColors.ink)),
                    Text(locked ? requirement : '${mission.type.label} · ${mission.question}',
                        style: AppText.small.copyWith(fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (stars > 0) StarRow(stars) else if (!locked) const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.heading),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.small),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Bottom panel shell: drag handle, close, scrollable body. Not modal —
/// the map stays interactive above it.
class _Shell extends StatelessWidget {
  const _Shell({required this.header, required this.children, required this.onClose, required this.onToggle});

  final Widget header;
  final List<Widget> children;
  final VoidCallback onClose;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MapPanel(
      onClose: onClose,
      onHandleTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 12), ...children],
      ),
    );
  }
}

/// Shared look for every panel that sits on the map.
class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.child, required this.onClose, this.onHandleTap, this.maxHeightFactor = 0.56});

  final Widget child;
  final VoidCallback onClose;
  final VoidCallback? onHandleTap;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: h * maxHeightFactor),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: GestureDetector(
                    onTap: onHandleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.inkFaint.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ),
                IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: onClose),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
