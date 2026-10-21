import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utilities/motion.dart';
import '../../data/local_data/achievements_data.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/player_progress.dart';
import '../../data/models/world.dart';
import '../../domain/game_engine.dart';
import '../../domain/geodesy.dart';
import '../../domain/progression.dart';
import '../../domain/world_rules.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/brand.dart';
import '../../state/game_controller.dart';
import '../missions/field_evidence_screen.dart';
import '../missions/land_cover_screen.dart';
import '../missions/quiz_screen.dart';
import '../sorting_game/sorting_screen.dart';
import 'explore_sheets.dart';
import 'map_markers.dart';
import 'site_sheet.dart';

/// The home screen IS the map of Greater Tunis.
///
/// Loop: discover a place → inspect it in a panel → investigate (trace,
/// measure, compare on the map, or a focused activity) → learn → reveal the
/// next place. The map keeps its camera and selection while activities run.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  final MapController _map = MapController();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  LatLng _flyFrom = kTunisCenter;
  LatLng _flyTarget = kTunisCenter;
  double _flyFromZoom = kTunisZoom;
  double _flyTargetZoom = kTunisZoom;

  LayerState _layers = const LayerState();
  double _split = 0.5;
  String? _selectedId;
  bool _expanded = false;
  Mission? _task;
  final List<LatLng> _points = [];
  MissionResult? _result;
  bool? _online;
  bool _reduced = false;
  bool _journeyQueued = false;
  StreamSubscription<String>? _achievementSub;

  @override
  void initState() {
    super.initState();
    _fly.addListener(_onFlyTick);
    final game = context.read<GameController>();
    _achievementSub = game.achievementUnlocks.listen(_toastAchievement);
    if (context.read<AppConfig>().networkTiles) _checkConnection();
  }

  /// Keeps the marker pulse in sync with reduced-motion preferences.
  void _syncMotion(bool reduced) {
    if (reduced == _reduced && _pulse.isAnimating != reduced) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _reduced = reduced);
      if (reduced) {
        _pulse.stop();
      } else if (!_pulse.isAnimating) {
        _pulse.repeat();
      }
    });
  }

  Future<void> _checkConnection() async {
    try {
      final r = await InternetAddress.lookup('server.arcgisonline.com').timeout(const Duration(seconds: 4));
      if (mounted) setState(() => _online = r.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _online = false);
    }
  }

  @override
  void dispose() {
    _achievementSub?.cancel();
    _fly.dispose();
    _pulse.dispose();
    _map.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- camera

  (LatLng, double) _camera() {
    try {
      final c = _map.camera;
      return (c.center, c.zoom);
    } catch (_) {
      return (kTunisCenter, kTunisZoom);
    }
  }

  void _onFlyTick() {
    final t = Curves.easeInOutCubic.transform(_fly.value);
    final lat = _flyFrom.latitude + (_flyTarget.latitude - _flyFrom.latitude) * t;
    final lon = _flyFrom.longitude + (_flyTarget.longitude - _flyFrom.longitude) * t;
    final z = _flyFromZoom + (_flyTargetZoom - _flyFromZoom) * t;
    try {
      _map.move(LatLng(lat, lon), z);
    } catch (_) {
      // Controller not attached yet.
    }
  }

  /// Smoothly moves the camera so [point] sits in the upper part of the
  /// screen, above the panel.
  void _flyTo(LatLng point, double zoom, {double panelShare = 0.22}) {
    final h = MediaQuery.of(context).size.height;
    final metersPerPixel = 156543.03392 * math.cos(point.latitude * math.pi / 180) / math.pow(2, zoom);
    final dLat = (h * panelShare) * metersPerPixel / 111320.0;
    final target = LatLng(point.latitude - dLat, point.longitude);
    final (from, fromZoom) = _camera();
    _flyFrom = from;
    _flyFromZoom = fromZoom;
    _flyTarget = target;
    _flyTargetZoom = zoom;
    if (_reduced) {
      _fly.value = 1;
      _onFlyTick();
    } else {
      _fly.forward(from: 0);
    }
  }

  // ------------------------------------------------------------- actions

  void _select(RealSite site) {
    setState(() {
      _selectedId = site.id;
      _expanded = false;
      _task = null;
      _points.clear();
      _result = null;
    });
    _flyTo(site.center, site.focusZoom);
  }

  void _deselect() => setState(() {
        _selectedId = null;
        _task = null;
        _points.clear();
        _result = null;
      });

  Future<void> _start(Mission m) async {
    final game = context.read<GameController>();
    if (game.stateOf(m) == MissionState.locked) return;
    final site = siteById(m.siteId);
    if (m.type.onMap) {
      setState(() {
        _task = m;
        _selectedId = site.id;
        _points.clear();
        _result = null;
        _layers = m.type == MissionType.timeMachine
            ? _layers.copyWith(compare: true)
            : _layers.copyWith(compare: false, base: 'esri');
      });
      final centre = m.type == MissionType.measure
          ? LatLng(
              (siteById(SiteIds.medina).center.latitude + site.center.latitude) / 2,
              (siteById(SiteIds.medina).center.longitude + site.center.longitude) / 2,
            )
          : site.center;
      _flyTo(centre, m.focusZoom ?? site.focusZoom, panelShare: 0.18);
      return;
    }
    final Widget page = switch (m.type) {
      MissionType.sorting => const SortingScreen(),
      MissionType.quiz => QuizScreen(missionId: m.id),
      MissionType.landCover => LandCoverScreen(missionId: m.id),
      MissionType.fieldEvidence => FieldEvidenceScreen(missionId: m.id),
      _ => const SizedBox.shrink(),
    };
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {}); // back on the same place, same camera.
  }

  void _onMapTap(LatLng point) {
    final m = _task;
    if (m == null) {
      if (_selectedId != null) _deselect();
      return;
    }
    if (_result != null) return;
    setState(() {
      switch (m.type) {
        case MissionType.measure:
          if (_points.length >= 2) _points.clear();
          _points.add(point);
        case MissionType.timeMachine:
          if (_points.length < m.markersNeeded) _points.add(point);
        default:
          _points.add(point);
      }
    });
    if (context.read<GameController>().settings.haptics) HapticFeedback.selectionClick().ignore();
  }

  bool get _canCheck {
    final m = _task;
    if (m == null || _result != null) return false;
    return switch (m.type) {
      MissionType.digitize => _points.length >= 3,
      MissionType.measure => _points.length == 2,
      MissionType.timeMachine => _points.length >= m.markersNeeded,
      _ => false,
    };
  }

  void _check() {
    final m = _task;
    if (m == null || !_canCheck) return;
    final game = context.read<GameController>();
    final r = switch (m.type) {
      MissionType.digitize => game.completeTrace(m.id, List.of(_points)),
      MissionType.measure => game.completeMeasure(m.id, _points[0], _points[1]),
      _ => game.completeTimeMachine(m.id, List.of(_points)),
    };
    setState(() => _result = r);
  }

  void _toastAchievement(String id) {
    if (!mounted) return;
    final a = achievementById(id);
    if (a == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.midnight,
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(a.icon, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Achievement · ${a.title}', style: AppText.bodyStrong.copyWith(color: AppColors.onDark)),
          ),
        ],
      ),
    ));
  }

  Future<void> _openAnnotation(String id) async {
    final p = context.read<GameController>().progress;
    final a = p.annotations.where((x) => x.id == id).firstOrNull;
    if (a == null) return;
    final delete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.limestone,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My annotation', style: AppText.heading),
              const SizedBox(height: 4),
              Text(a.note, style: AppText.bodyText),
              const SizedBox(height: 6),
              Text('${a.lat.toStringAsFixed(5)}, ${a.lon.toStringAsFixed(5)} · placed by you on the imagery (not GPS, not verified)',
                  style: AppText.data),
              const SizedBox(height: 14),
              BladnaButton(
                label: 'Delete annotation',
                style: BladnaButtonStyle.quiet,
                icon: Icons.delete_outline_rounded,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (delete == true && mounted) context.read<GameController>().removeAnnotation(id);
  }

  // -------------------------------------------------------------- build

  Basemap get _base => _layers.compare ? kBasemapS2024 : kBasemaps.firstWhere((b) => b.id == _layers.base);

  TileLayer _tiles(Basemap b) => TileLayer(
        key: ValueKey('tiles-${b.id}'),
        urlTemplate: b.urlTemplate,
        maxNativeZoom: b.maxNativeZoom,
        userAgentPackageName: 'tn.greenhackathon2026.bladna',
      );

  SiteVisual _visual(PlayerProgress p, RealSite s) {
    if (!WorldRules.isRevealed(p, s)) return SiteVisual.hidden;
    return WorldRules.siteComplete(p, s.id) ? SiteVisual.explored : SiteVisual.open;
  }

  List<Widget> _layersFor(PlayerProgress p, List<String> justRevealed, bool tiles) {
    final m = _task;
    final revealed = WorldRules.revealedSites(p);
    return [
      if (tiles) _tiles(_base),
      if (tiles && _layers.compare)
        SizedBox.expand(child: ClipRect(clipper: _LeftClip(_split), child: _tiles(kBasemapS2016))),
      if (_layers.investigation)
        CircleLayer(circles: [
          for (final s in kSites)
            if (revealed.contains(s.id) && WorldRules.siteComplete(p, s.id))
              CircleMarker(
                point: s.center,
                radius: s.approximate ? s.approxRadiusMeters : 900,
                useRadiusInMeter: true,
                color: AppColors.restored.withValues(alpha: 0.16),
                borderColor: AppColors.restored.withValues(alpha: 0.8),
                borderStrokeWidth: 1.5,
              )
            else if (revealed.contains(s.id) && s.approximate)
              CircleMarker(
                point: s.center,
                radius: s.approxRadiusMeters,
                useRadiusInMeter: true,
                color: AppColors.warning.withValues(alpha: 0.12),
                borderColor: AppColors.warning,
                borderStrokeWidth: 1.5,
              ),
        ]),
      if (_layers.investigation)
        PolylineLayer(polylines: [
          for (final s in kSites)
            if (revealed.contains(s.id) && s.revealedBy.isNotEmpty)
              Polyline(
                points: [siteById(_trailFrom(p, s)).center, s.center],
                color: AppColors.midnight.withValues(alpha: 0.75),
                strokeWidth: 2,
                borderColor: Colors.white.withValues(alpha: 0.7),
                borderStrokeWidth: 1,
              ),
        ]),
      if (m != null && m.type == MissionType.digitize && _points.length >= 3)
        PolygonLayer(polygons: [
          Polygon(
            points: List.of(_points),
            color: AppColors.action.withValues(alpha: 0.25),
            borderColor: AppColors.action,
            borderStrokeWidth: 3,
          ),
        ]),
      if (m != null && m.type != MissionType.timeMachine && _points.length >= 2 &&
          !(m.type == MissionType.digitize && _points.length >= 3))
        PolylineLayer(polylines: [
          Polyline(points: List.of(_points), color: AppColors.action, strokeWidth: 3.5, borderColor: Colors.white, borderStrokeWidth: 1),
        ]),
      MarkerLayer(markers: [
        if (_layers.annotations)
          for (final a in p.annotations)
            Marker(
              point: LatLng(a.lat, a.lon),
              width: 26,
              height: 26,
              child: AnnotationMarker(onTap: () => _openAnnotation(a.id)),
            ),
        for (final s in kSites)
          Marker(
            point: s.center,
            width: 170,
            height: 80,
            alignment: const Alignment(0, 0.3),
            child: SiteMarker(
              site: s,
              visual: _visual(p, s),
              selected: _selectedId == s.id,
              done: WorldRules.siteProgress(p, s.id).$1,
              total: WorldRules.siteProgress(p, s.id).$2,
              pulse: _reduced ? null : _pulse,
              justRevealed: justRevealed.contains(s.id),
              onTap: () => _select(s),
            ),
          ),
        for (var i = 0; i < _points.length; i++)
          Marker(
            point: _points[i],
            width: 24,
            height: 24,
            child: TaskPoint(index: i + 1, color: m?.type == MissionType.timeMachine ? AppColors.secondary : AppColors.action),
          ),
      ]),
    ];
  }

  /// The place whose mission revealed [s] (for the exploration trail).
  String _trailFrom(PlayerProgress p, RealSite s) {
    for (final id in s.revealedBy) {
      if (p.isMissionDone(id)) return missionById(id)?.siteId ?? s.id;
    }
    return missionById(s.revealedBy.first)?.siteId ?? s.id;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final p = game.progress;
    final tiles = context.read<AppConfig>().networkTiles;
    _syncMotion(MotionPrefs.reduced(context));
    if (!p.onboardingDone && !_journeyQueued) {
      // First visit, or after "Erase all progress".
      _journeyQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _journeyQueued = false;
        if (mounted && !context.read<GameController>().progress.onboardingDone) {
          context.read<GameController>().startJourney();
        }
      });
    }
    final selected = _selectedId == null ? null : siteById(_selectedId!);
    final next = game.nextMission;
    final level = Progression.levelFor(p.xp);

    Widget bottom;
    if (_task != null) {
      bottom = _taskPanel(_task!);
    } else if (selected != null) {
      bottom = SiteSheet(
        site: selected,
        expanded: _expanded,
        onToggle: () => setState(() => _expanded = !_expanded),
        onClose: _deselect,
        onStart: _start,
      );
    } else {
      bottom = SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: next == null
                    ? _Pill(icon: Icons.verified_outlined, text: 'Every mission complete — keep exploring', onTap: null)
                    : _Pill(
                        icon: Icons.near_me_rounded,
                        text: 'Next: ${next.title} · ${siteById(next.siteId).name}',
                        onTap: () => _select(siteById(next.siteId)),
                        accent: true,
                      ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.zoom_out_map_rounded,
                tooltip: 'Show all of Greater Tunis',
                onMap: true,
                onPressed: () => _flyTo(kTunisCenter, kTunisZoom, panelShare: 0),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: kTunisCenter,
                initialZoom: kTunisZoom,
                minZoom: 9,
                maxZoom: 18,
                backgroundColor: AppColors.midnightSoft,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: _layersFor(p, game.justRevealed, tiles),
            ),
          ),
          if (_layers.compare)
            LayoutBuilder(builder: (context, c) {
              return Stack(children: [
                Positioned(
                  left: _split * c.maxWidth - 1.5,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(child: Container(width: 3, color: AppColors.limestone)),
                ),
              ]);
            }),
          // Top controls.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Level $level, ${p.xp} XP. Open menu.',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => showAtlasMenu(context),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
                            decoration: mapControlDecoration(radius: 23),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const BladnaMark(size: 30, variant: MarkVariant.onDark),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: Progression.levelFraction(p.xp),
                                        strokeWidth: 3,
                                        color: AppColors.action,
                                        backgroundColor: Colors.white24,
                                      ),
                                      Text('$level', style: AppText.data.copyWith(color: AppColors.onDark, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${p.xp} XP', style: AppText.data.copyWith(color: AppColors.onDark)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'Search places',
                        onMap: true,
                        onPressed: () async {
                          final s = await showPlaceSearch(context);
                          if (s != null && mounted) _select(s);
                        },
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.layers_outlined,
                        tooltip: 'Map layers',
                        onMap: true,
                        onPressed: () async {
                          final l = await showLayerMenu(context, _layers);
                          if (l != null && mounted) setState(() => _layers = l);
                        },
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.menu_rounded,
                        tooltip: 'Discoveries, progress and settings',
                        onMap: true,
                        onPressed: () => showAtlasMenu(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_online == false)
                    const _Banner(
                      icon: Icons.cloud_off_rounded,
                      text: 'No connection — imagery can\'t load. Places, missions and your journal still work.',
                    )
                  else if (!p.isMissionDone(MissionIds.fieldTraining) && selected == null)
                    const _Banner(
                      icon: Icons.touch_app_outlined,
                      text: 'Start in the Medina: tap the glowing pin.',
                    ),
                  if (_layers.compare)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          _YearTag('◀ 2016'),
                          Spacer(),
                          _YearTag('2024 ▶'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: bottom),
          // Attribution: legible and close to the imagery.
          Positioned(
            left: 6,
            right: 6,
            bottom: _task != null || selected != null ? null : 74,
            top: _task != null || selected != null ? MediaQuery.of(context).padding.top + 112 : null,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.midnight.withValues(alpha: 0.55),
                  child: Text(
                    tiles
                        ? (_layers.compare ? '${kBasemapS2016.attribution} | ${kBasemapS2024.attribution}' : _base.attribution)
                        : 'Imagery disabled (test mode)',
                    style: AppText.small.copyWith(color: Colors.white, fontSize: 9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskPanel(Mission m) {
    final r = _result;
    final readout = switch (m.type) {
      MissionType.digitize => _points.length < 3
          ? '${_points.length} point(s) — add at least 3'
          : '${_points.length} points · ${Geodesy.formatArea(Geodesy.polygonArea(_points))}',
      MissionType.measure => _points.length < 2
          ? (_points.isEmpty ? 'Tap the start point' : 'Now tap the end point')
          : 'Distance · ${Geodesy.formatDistance(Geodesy.distance(_points[0], _points[1]))}',
      _ => '${_points.length} / ${m.markersNeeded} observations pinned',
    };
    return MapPanel(
      onClose: () => setState(() {
        _task = null;
        _points.clear();
        _result = null;
      }),
      maxHeightFactor: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagChip(text: m.type.label.toUpperCase(), color: AppColors.midnight, textColor: AppColors.onDark),
              const SizedBox(width: 8),
              Expanded(child: Text(siteById(m.siteId).name, style: AppText.small, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(m.title, style: AppText.heading),
          const SizedBox(height: 4),
          Text(m.question, style: AppText.bodyText.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          if (r == null) ...[
            Text(m.task, style: AppText.bodyStrong),
            const SizedBox(height: 4),
            Text(m.rule, style: AppText.small),
            if (m.type == MissionType.timeMachine)
              Row(
                children: [
                  Text('2016', style: AppText.data),
                  Expanded(
                    child: Slider(
                      value: _split,
                      onChanged: (v) => setState(() => _split = v),
                      activeColor: AppColors.action,
                      semanticFormatterCallback: (v) => '${(v * 100).round()} percent showing 2016',
                    ),
                  ),
                  Text('2024', style: AppText.data),
                ],
              ),
            const SizedBox(height: 8),
            Text(readout, style: AppText.data.copyWith(color: AppColors.ink, fontSize: 13.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: BladnaButton(
                    label: 'Undo',
                    icon: Icons.undo_rounded,
                    style: BladnaButtonStyle.quiet,
                    onPressed: _points.isEmpty ? null : () => setState(_points.removeLast),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: BladnaButton(label: 'Check', icon: Icons.fact_check_outlined, onPressed: _canCheck ? _check : null)),
              ],
            ),
          ] else ...[
            Row(
              children: [
                StarRow(r.stars, size: 24),
                const SizedBox(width: 10),
                if (r.outcome.xpGained > 0)
                  TagChip(text: '+${r.outcome.xpGained} XP', color: AppColors.action, textColor: Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.summary, style: AppText.bodyText),
            if (r.outcome.message != null) Text(r.outcome.message!, style: AppText.small),
            if (r.outcome.revealedSites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Revealed on the map: ${r.outcome.revealedSites.map((id) => siteById(id).name).join(', ')}',
                  style: AppText.bodyStrong.copyWith(color: AppColors.restored),
                ),
              ),
            const SizedBox(height: 8),
            Text('WHAT THIS TEACHES', style: AppText.label),
            const SizedBox(height: 2),
            Text(m.learning, style: AppText.bodyText),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BladnaButton(
                    label: 'Try again',
                    icon: Icons.replay_rounded,
                    style: BladnaButtonStyle.quiet,
                    onPressed: () => setState(() {
                      _points.clear();
                      _result = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BladnaButton(
                    label: 'Back to place',
                    icon: Icons.place_outlined,
                    style: BladnaButtonStyle.secondary,
                    onPressed: () => setState(() {
                      _task = null;
                      _points.clear();
                      _result = null;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeftClip extends CustomClipper<Rect> {
  _LeftClip(this.split);
  final double split;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(covariant _LeftClip oldClipper) => oldClipper.split != split;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.onTap, this.accent = false});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: mapControlDecoration(radius: 23),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent ? AppColors.action : AppColors.onDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(color: AppColors.onDark, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: mapControlDecoration(radius: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.small.copyWith(color: AppColors.onDark))),
        ],
      ),
    );
  }
}

class _YearTag extends StatelessWidget {
  const _YearTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: mapControlDecoration(radius: 8),
      child: Text(text, style: AppText.data.copyWith(color: AppColors.onDark)),
    );
  }
}
