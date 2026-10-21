import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../domain/game_engine.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import 'mission_result_view.dart';

/// Reasoning mission: one question at a time, explanation after each answer.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.missionId});

  final String missionId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<int> _answers = [];
  int? _picked;
  MissionResult? _result;

  @override
  Widget build(BuildContext context) {
    final m = missionById(widget.missionId)!;
    final site = siteById(m.siteId);
    final r = _result;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ActivityHeader(title: m.title, subtitle: '${site.name} · ${m.type.label}'),
            Expanded(
              child: r != null
                  ? MissionResultView(result: r, onAgain: () => setState(() {
                        _answers.clear();
                        _picked = null;
                        _result = null;
                      }))
                  : _question(context, m.quiz.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(BuildContext context, int total) {
    final m = missionById(widget.missionId)!;
    final i = _answers.length;
    final q = m.quiz[i];
    final picked = _picked;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (i == 0) ...[
          Text(m.question, style: AppText.bodyText.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Text('QUESTION ${i + 1} OF $total', style: AppText.label),
            const SizedBox(width: 10),
            Expanded(child: ChunkyProgress(value: i / total, semanticLabel: 'Quiz progress')),
          ],
        ),
        const SizedBox(height: 12),
        Text(q.prompt, style: AppText.subheading.copyWith(fontSize: 18, height: 1.35)),
        const SizedBox(height: 16),
        for (var k = 0; k < q.options.length; k++)
          _Option(
            text: q.options[k].text,
            state: picked == null
                ? _OptState.idle
                : (q.options[k].correct ? _OptState.correct : (k == picked ? _OptState.wrong : _OptState.idle)),
            onTap: picked == null ? () => setState(() => _picked = k) : null,
          ),
        if (picked != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              '${q.options[picked].correct ? 'Correct. ' : 'Not quite. '}${q.explanation}',
              style: AppText.bodyText,
            ),
          ),
          const SizedBox(height: 16),
          BladnaButton(
            label: i + 1 == total ? 'See result' : 'Next question',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              setState(() {
                _answers.add(picked);
                _picked = null;
              });
              if (_answers.length == total) {
                final res = context.read<GameController>().completeQuiz(m.id, List.of(_answers));
                setState(() => _result = res);
              }
            },
          ),
        ],
      ],
    );
  }
}

enum _OptState { idle, correct, wrong }

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.state, required this.onTap});

  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, IconData? icon, Color iconColor) = switch (state) {
      _OptState.idle => (AppColors.mineral, null, AppColors.inkFaint),
      _OptState.correct => (AppColors.restored, Icons.check_circle_rounded, AppColors.restored),
      _OptState.wrong => (AppColors.gentleError, Icons.cancel_outlined, AppColors.gentleError),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: onTap != null,
        label: '$text${state == _OptState.correct ? '. Correct answer' : (state == _OptState.wrong ? '. Your answer, incorrect' : '')}',
        excludeSemantics: true,
        child: Material(
          color: AppColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border, width: 1.5)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text(text, style: AppText.bodyText)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: iconColor)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
