import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/world.dart';
import '../../domain/game_engine.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import 'mission_result_view.dart';

/// Photo-interpretation: what covers most of this view? Each view is
/// centered on a documented place (educational examples, not a land-cover
/// dataset).
class LandCoverScreen extends StatefulWidget {
  const LandCoverScreen({super.key, required this.missionId});

  final String missionId;

  @override
  State<LandCoverScreen> createState() => _LandCoverScreenState();
}

class _LandCoverScreenState extends State<LandCoverScreen> {
  final List<LandCoverClass> _answers = [];
  LandCoverClass? _picked;
  MissionResult? _result;

  static double _zoomFor(LandCoverClass c) => switch (c) {
        LandCoverClass.builtUp => 15.5,
        LandCoverClass.wetland => 13,
        _ => 13.5,
      };

  static IconData _icon(LandCoverClass c) => switch (c) {
        LandCoverClass.water => Icons.water_rounded,
        LandCoverClass.vegetation => Icons.park_outlined,
        LandCoverClass.builtUp => Icons.location_city_rounded,
        LandCoverClass.bareSoil => Icons.terrain_rounded,
        LandCoverClass.wetland => Icons.waves_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final m = missionById(widget.missionId)!;
    final r = _result;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ActivityHeader(title: m.title, subtitle: '${siteById(m.siteId).name} · ${m.type.label}'),
            Expanded(
              child: r != null
                  ? MissionResultView(
                      result: r,
                      onAgain: () => setState(() {
                        _answers.clear();
                        _picked = null;
                        _result = null;
                      }),
                    )
                  : _view(context, m),
            ),
          ],
        ),
      ),
    );
  }

  Widget _view(BuildContext context, Mission m) {
    final i = _answers.length;
    final ex = m.landCover[i];
    final picked = _picked;
    final tiles = context.read<AppConfig>().networkTiles;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Text('VIEW ${i + 1} OF ${m.landCover.length}', style: AppText.label),
            const SizedBox(width: 10),
            Expanded(child: ChunkyProgress(value: i / m.landCover.length, semanticLabel: 'Progress')),
          ],
        ),
        const SizedBox(height: 10),
        Text(m.question, style: AppText.subheading.copyWith(fontSize: 18)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    key: ValueKey('lc-$i'),
                    options: MapOptions(
                      initialCenter: ex.point,
                      initialZoom: _zoomFor(ex.answer),
                      backgroundColor: AppColors.midnightSoft,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      if (tiles)
                        TileLayer(
                          urlTemplate: kBasemapEsri.urlTemplate,
                          maxNativeZoom: kBasemapEsri.maxNativeZoom,
                          userAgentPackageName: 'tn.greenhackathon2026.bladna',
                        ),
                    ],
                  ),
                ),
                const IgnorePointer(child: Center(child: Icon(Icons.add_rounded, size: 40, color: Colors.white))),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: AppColors.midnight.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text(
                      '${ex.point.latitude.toStringAsFixed(4)} N, ${ex.point.longitude.toStringAsFixed(4)} E · ${kBasemapEsri.attribution}',
                      style: AppText.small.copyWith(color: Colors.white, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Educational example centered on a documented place · ${ex.source}', style: AppText.data.copyWith(fontSize: 11)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in LandCoverClass.values)
              ChoiceChip(
                avatar: Icon(_icon(c), size: 18),
                label: Text(c.label),
                selected: picked == c,
                onSelected: picked != null ? null : (_) => setState(() => _picked = c),
                selectedColor: c == ex.answer ? AppColors.restored.withValues(alpha: 0.3) : AppColors.gentleError.withValues(alpha: 0.25),
              ),
          ],
        ),
        if (picked != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              picked == ex.answer
                  ? 'Correct — ${ex.answer.label}. ${ex.explanation}'
                  : 'This view is mostly ${ex.answer.label.toLowerCase()}. ${ex.explanation}',
              style: AppText.bodyText,
            ),
          ),
          const SizedBox(height: 14),
          BladnaButton(
            label: i + 1 == m.landCover.length ? 'See result' : 'Next view',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              setState(() {
                _answers.add(picked);
                _picked = null;
              });
              if (_answers.length == m.landCover.length) {
                final res = context.read<GameController>().completeLandCover(m.id, List.of(_answers));
                setState(() => _result = res);
              }
            },
          ),
        ],
      ],
    );
  }
}
