import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/game_rules.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utilities/motion.dart';
import '../../data/models/waste_category.dart';
import '../../data/models/waste_item.dart';
import '../../domain/game_engine.dart';
import '../../data/local_data/world_data.dart';
import '../../domain/sort_round_planner.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import 'bin_widget.dart';
import 'waste_item_painter.dart';

enum _Phase { choosing, wrong, correct, revealed, summary }

/// The sorting mini-game: one item at a time, drag OR tap a bin.
class SortingScreen extends StatefulWidget {
  const SortingScreen({super.key, this.focus = const [], this.missionId});

  /// Categories prioritised because a mission launched this round.
  final List<WasteCategory> focus;
  final String? missionId;

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _RoundResult {
  _RoundResult(this.item, this.xp, this.learned);
  final WasteItem item;
  final int xp;
  final bool learned;
}

class _SortingScreenState extends State<SortingScreen> {
  late List<WasteItem> _round;
  late bool _practice;
  int _index = 0;
  int _wrong = 0;
  _Phase _phase = _Phase.choosing;
  SortOutcome? _last;
  WasteCategory? _lastChoice;
  final List<_RoundResult> _results = [];
  int _learnedBefore = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final p = context.read<GameController>().progress;
    _practice = SortRoundPlanner.allMastered(p);
    _round = SortRoundPlanner.plan(p, focus: widget.focus);
    _index = 0;
    _wrong = 0;
    _phase = _Phase.choosing;
    _last = null;
    _lastChoice = null;
    _results.clear();
    _learnedBefore = p.masteredItems.length;
  }

  WasteItem get _item => _round[_index];

  void _choose(WasteCategory category) {
    if (_phase != _Phase.choosing && _phase != _Phase.wrong) return;
    final game = context.read<GameController>();
    final result = game.sort(_item, category, previousWrong: _wrong);
    if (game.settings.haptics) {
      if (result.correct) {
        HapticFeedback.lightImpact().ignore();
      } else {
        HapticFeedback.selectionClick().ignore();
      }
    }
    setState(() {
      _last = result;
      _lastChoice = category;
      if (result.correct) {
        _phase = _Phase.correct;
        _results.add(_RoundResult(_item, result.outcome.xpGained, result.newlyMastered));
      } else {
        _wrong = result.wrongCount;
        if (result.revealAnswer) {
          _phase = _Phase.revealed;
          _results.add(_RoundResult(_item, 0, false));
        } else {
          _phase = _Phase.wrong;
        }
      }
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= _round.length) {
        _phase = _Phase.summary;
      } else {
        _index++;
        _wrong = 0;
        _last = null;
        _lastChoice = null;
        _phase = _Phase.choosing;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mission = missionById(widget.missionId ?? MissionIds.fieldTraining);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to the map',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission?.title ?? 'Field Training', style: AppText.heading),
                        Text(
                          'Medina of Tunis · sorting',
                          style: AppText.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_phase != _Phase.summary) _ProgressDots(total: _round.length, index: _index, results: _results.length),
                ],
              ),
            ),
            Expanded(
              child: _phase == _Phase.summary ? _summary(context) : _playArea(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playArea(BuildContext context) {
    final item = _item;
    final binsEnabled = _phase == _Phase.choosing || _phase == _Phase.wrong;
    final reduced = MotionPrefs.reduced(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_practice)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: TagChip(
              text: 'PRACTICE ROUND — every item learned, no extra XP',
              color: AppColors.sand,
              icon: Icons.replay_rounded,
            ),
          ),
        _ItemCard(
          key: ValueKey('item-${item.id}-$_index'),
          item: item,
          celebrate: _phase == _Phase.correct,
          shake: _phase == _Phase.wrong,
          shakeCount: _wrong,
          draggable: binsEnabled,
          reduced: reduced,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: MotionPrefs.duration(context, const Duration(milliseconds: 250)),
          child: _feedback(context, item),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final cat in WasteCategory.values)
              SortingBin(
                category: cat,
                enabled: binsEnabled,
                state: _binState(cat),
                onChosen: () => _choose(cat),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Collection rules differ between municipalities. These are general examples — always check your local guidance.',
          style: AppText.small.copyWith(fontSize: 12, color: AppColors.inkFaint),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  BinState _binState(WasteCategory cat) {
    if (_phase == _Phase.correct && cat == _item.category) return BinState.correct;
    if (_phase == _Phase.revealed && cat == _item.category) return BinState.correct;
    if ((_phase == _Phase.wrong || _phase == _Phase.revealed) && cat == _lastChoice) return BinState.wrong;
    return BinState.idle;
  }

  Widget _feedback(BuildContext context, WasteItem item) {
    final last = _last;
    switch (_phase) {
      case _Phase.choosing:
        return Text(
          'Drag the item onto a bin — or simply tap the bin.',
          key: const ValueKey('prompt'),
          style: AppText.note.copyWith(fontSize: 20),
          textAlign: TextAlign.center,
        );
      case _Phase.wrong:
        final hint = item.mistakeHint ?? 'Think about what it is made of, and whether it is clean and empty.';
        return _FeedbackCard(
          key: ValueKey('wrong-$_wrong'),
          color: const Color(0xFFF6E2D6),
          icon: Icons.refresh_rounded,
          iconColor: AppColors.gentleError,
          title: _wrong == 1 ? 'Not quite — try again' : 'Almost! One more look',
          body: last?.showHint == true ? 'Hint: $hint' : 'Not the ${_lastChoice?.shortLabel ?? ''} bin. Try another one.',
          extra: _wrong >= GameRules.revealAfterWrong - 1
              ? 'If the next try misses, we will show the answer — no penalty.'
              : null,
        );
      case _Phase.correct:
        final xp = last?.outcome.xpGained ?? 0;
        final training = last?.outcome.progress.isMissionDone(MissionIds.fieldTraining) ?? false;
        final notes = [
          if (item.safetyNote != null) 'Safety: ${item.safetyNote}',
          if (item.dependsOnLocalRules) 'This one depends on local collection rules — check your municipality.',
        ];
        return _FeedbackCard(
          key: const ValueKey('correct'),
          color: const Color(0xFFE3EDD3),
          icon: Icons.check_rounded,
          iconColor: AppColors.success,
          title: last?.newlyMastered == true ? 'Well sorted!' : 'Correct — already learned',
          chips: [
            if (xp > 0) '+$xp XP',
            if (training && (last?.outcome.revealedSites.isNotEmpty ?? false)) 'Field Training complete',
            if (last?.newlyMastered != true) 'Practice · no XP',
          ],
          body: item.explanation,
          extra: notes.isEmpty ? null : notes.join('\n'),
          action: BladnaButton(
            label: _index + 1 >= _round.length ? 'See round summary' : 'Next item',
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        );
      case _Phase.revealed:
        return _FeedbackCard(
          key: const ValueKey('revealed'),
          color: const Color(0xFFF3E9C9),
          icon: Icons.lightbulb_outline_rounded,
          iconColor: AppColors.ochre,
          title: 'It goes in: ${item.category.label}',
          body: item.explanation,
          extra: [
            'No XP this time — it will come back in a later round so you can earn it.',
            if (item.safetyNote != null) 'Safety: ${item.safetyNote}',
          ].join('\n'),
          action: BladnaButton(
            label: _index + 1 >= _round.length ? 'See round summary' : 'Next item',
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        );
      case _Phase.summary:
        return const SizedBox.shrink();
    }
  }

  Widget _summary(BuildContext context) {
    final game = context.watch<GameController>();
    final xp = _results.fold<int>(0, (sum, r) => sum + r.xp);
    final learned = _results.where((r) => r.learned).length;
    final learnedNow = game.progress.masteredItems.length;
    final trainingDone = game.progress.isMissionDone(MissionIds.fieldTraining);
    final justFinished = trainingDone && _learnedBefore < GameRules.fieldTrainingItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Round complete', style: AppText.title),
        const SizedBox(height: 4),
        Text('Here is what you learned.', style: AppText.bodyText),
        const SizedBox(height: 14),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow(Icons.school_outlined, 'New items learned', '$learned of ${_results.length}'),
              _statRow(Icons.star_rounded, 'XP earned (game score)', '+$xp'),
              _statRow(Icons.flag_outlined, 'Field Training',
                  trainingDone ? 'Complete' : '$learnedNow / ${GameRules.fieldTrainingItems} items learned'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final r in _results)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 36, height: 36, child: CustomPaint(painter: WasteItemPainter(r.item.shape))),
                const SizedBox(width: 10),
                Expanded(child: Text(r.item.name, style: AppText.bodyText)),
                Text(r.item.category.shortLabel, style: AppText.small),
                const SizedBox(width: 8),
                Icon(
                  r.learned ? Icons.check_circle_rounded : (r.xp == 0 ? Icons.replay_circle_filled_rounded : Icons.check_circle_outline),
                  color: r.learned ? AppColors.success : AppColors.inkFaint,
                  size: 20,
                  semanticLabel: r.learned ? 'Learned' : 'Practice',
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (justFinished)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.restored.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded, color: AppColors.restored),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Field Training complete. A new place has been revealed on the map: Borj Chakir.',
                        style: AppText.bodyStrong),
                  ),
                ],
              ),
            ),
          ),
        BladnaButton(
          label: 'Play another round',
          icon: Icons.replay_rounded,
          onPressed: () => setState(_newRound),
        ),
        const SizedBox(height: 10),
        BladnaButton(
          label: 'Back to the map',
          style: BladnaButtonStyle.secondary,
          icon: Icons.map_outlined,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.terracotta),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppText.bodyText)),
          Text(value, style: AppText.bodyStrong),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.index, required this.results});

  final int total;
  final int index;
  final int results;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Item ${index + 1} of $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: i < results ? AppColors.olive : (i == index ? AppColors.ochre : AppColors.paper),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.celebrate,
    required this.shake,
    required this.shakeCount,
    required this.draggable,
    required this.reduced,
  });

  final WasteItem item;
  final bool celebrate;
  final bool shake;
  final int shakeCount;
  final bool draggable;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final art = SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(painter: WasteItemPainter(item.shape)),
    );
    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: stickerDecoration(color: celebrate ? const Color(0xFFE3EDD3) : AppColors.paper, radius: 20),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey('bounce-$celebrate'),
            tween: Tween(begin: celebrate && !reduced ? 0.85 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: draggable
                ? Draggable<String>(
                    data: item.id,
                    feedback: Material(type: MaterialType.transparency, child: art),
                    childWhenDragging: Opacity(opacity: 0.3, child: art),
                    child: Semantics(label: 'Waste item: ${item.name}', child: art),
                  )
                : Semantics(label: 'Waste item: ${item.name}', child: art),
          ),
          const SizedBox(height: 6),
          Text(item.name, style: AppText.heading, textAlign: TextAlign.center),
          if (item.dependsOnLocalRules) ...[
            const SizedBox(height: 6),
            const TagChip(text: 'Depends on local rules', color: AppColors.cream, icon: Icons.place_outlined),
          ],
        ],
      ),
    );
    if (!shake || reduced) return card;
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-$shakeCount'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      builder: (context, t, child) {
        final dx = (1 - t) * 8 * ((t * 6).floor().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: card,
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    super.key,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.chips = const [],
    this.extra,
    this.action,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<String> chips;
  final String? extra;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: stickerDecoration(color: color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: stickerDecoration(color: iconColor, radius: 16, shadow: 0),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: AppText.subheading)),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final c in chips) TagChip(text: c, color: AppColors.paper)],
              ),
            ],
            const SizedBox(height: 8),
            Text(body, style: AppText.bodyText),
            if (extra != null) ...[
              const SizedBox(height: 6),
              Text(extra!, style: AppText.small),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
