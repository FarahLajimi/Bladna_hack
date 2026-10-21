import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/labeled_photo.dart';
import '../../data/models/waste_category.dart';
import '../../data/repositories/dataset_store.dart';
import '../../domain/game_engine.dart';
import '../../domain/vision/waste_vision_model.dart';
import '../../domain/world_rules.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';

/// Field Evidence: capture → review → identify → note → link → save.
///
/// With no model installed (this build) every record is a MANUAL
/// observation and is labelled as such. No GPS is read; a record can be
/// linked to a mission as a game record, which is not the photo's location.
/// Camera/gallery permission is requested by the system only when the
/// player taps Camera or Gallery.
class FieldEvidenceScreen extends StatefulWidget {
  const FieldEvidenceScreen({super.key, this.missionId});

  /// The mission this record is for (null when opened from Discoveries).
  final String? missionId;

  @override
  State<FieldEvidenceScreen> createState() => _FieldEvidenceScreenState();
}

class _FieldEvidenceScreenState extends State<FieldEvidenceScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _note = TextEditingController();
  String? _path;
  VisionPrediction? _prediction;
  WasteCategory? _category;
  bool _link = true;
  bool _busy = false;
  GameOutcome? _saved;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 82);
      if (x == null || !mounted) return;
      final prediction = await kWasteVisionModel.classify(x.path);
      if (!mounted) return;
      setState(() {
        _path = x.path;
        _prediction = prediction;
        _category = prediction?.category;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'The camera or gallery could not be opened on this device.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final path = _path;
    final cat = _category;
    if (path == null || cat == null) return;
    setState(() => _busy = true);
    try {
      final game = context.read<GameController>();
      final id = 'r${game.now().millisecondsSinceEpoch}';
      final stored = await DatasetStore.importPhoto(path, id);
      if (!mounted) return;
      final linked = widget.missionId != null && _link;
      final outcome = game.addFieldRecord(LabeledPhoto(
        id: id,
        path: stored,
        categoryId: cat.id,
        timestamp: game.now(),
        note: _note.text.trim(),
        missionId: linked ? widget.missionId : null,
        location: linked ? RecordLocation.missionLink : RecordLocation.none,
        modelPrediction: _prediction?.category.id,
        modelName: _prediction?.methodId,
      ));
      setState(() => _saved = outcome);
    } catch (_) {
      if (mounted) setState(() => _error = 'The photo could not be saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.missionId == null ? null : missionById(widget.missionId!);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ActivityHeader(
              title: mission?.title ?? 'Field evidence',
              subtitle: mission == null ? 'New record' : '${siteById(mission.siteId).name} · ${mission.type.label}',
            ),
            Expanded(child: _saved != null ? _done(context) : _form(context, mission?.title)),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, String? missionTitle) {
    final path = _path;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _Step(n: 1, title: 'Capture', done: path != null),
        Text(
          'Photograph one real waste item at home or school. Only safe items — never broken glass, needles, chemicals or batteries that leak — and no people in the frame.',
          style: AppText.small,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BladnaButton(
                label: path == null ? 'Camera' : 'Retake',
                icon: Icons.photo_camera_outlined,
                style: BladnaButtonStyle.secondary,
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BladnaButton(
                label: 'Gallery',
                icon: Icons.photo_library_outlined,
                style: BladnaButtonStyle.quiet,
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (path != null) ...[
          const SizedBox(height: 14),
          _Step(n: 2, title: 'Review', done: true),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(path), fit: BoxFit.cover, cacheWidth: 900,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined))),
            ),
          ),
          const SizedBox(height: 14),
          _Step(n: 3, title: 'Identify', done: _category != null),
          _ModelStatus(prediction: _prediction),
          const SizedBox(height: 8),
          for (final c in WasteCategory.values)
            RadioListTile<WasteCategory>(
              contentPadding: EdgeInsets.zero,
              value: c,
              groupValue: _category,
              onChanged: (v) => setState(() => _category = v),
              secondary: CircleAvatar(radius: 14, backgroundColor: c.color, child: Icon(c.icon, size: 15, color: Colors.white)),
              title: Text(c.label, style: AppText.bodyStrong),
              subtitle: Text(c.hint, style: AppText.small.copyWith(fontSize: 12)),
            ),
          const SizedBox(height: 8),
          _Step(n: 4, title: 'Note (optional)', done: _note.text.isNotEmpty),
          TextField(
            controller: _note,
            maxLength: 140,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. "Rinsed yogurt pot, lid removed"'),
          ),
          if (missionTitle != null) ...[
            _Step(n: 5, title: 'Link', done: true),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _link,
              onChanged: (v) => setState(() => _link = v),
              title: Text('Attach to "$missionTitle"', style: AppText.bodyStrong),
              subtitle: Text(
                'A game record only — it does not say where the photo was taken. BLADNA never reads your GPS.',
                style: AppText.small,
              ),
            ),
          ],
          if (_error != null) Text(_error!, style: AppText.small.copyWith(color: AppColors.gentleError)),
          const SizedBox(height: 12),
          BladnaButton(
            label: _busy ? 'Saving…' : 'Save record',
            icon: Icons.save_alt_rounded,
            onPressed: _busy || _category == null ? null : _save,
          ),
          const SizedBox(height: 8),
          Text('Saved only on this phone, in the app\'s private folder. Delete or export it any time from My discoveries.',
              style: AppText.small.copyWith(fontSize: 12)),
        ] else if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppText.small.copyWith(color: AppColors.gentleError)),
        ],
      ],
    );
  }

  Widget _done(BuildContext context) {
    final o = _saved!;
    final missionDone = widget.missionId != null &&
        WorldRules.stateOf(o.progress, missionById(widget.missionId!)!) == MissionState.done;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Icon(Icons.check_circle_rounded, size: 44, color: AppColors.restored),
        const SizedBox(height: 10),
        Text('Record saved', style: AppText.title),
        const SizedBox(height: 6),
        Text(
          'Manual observation: ${WasteCategory.fromId(o.progress.fieldRecords.last.categoryId)?.label ?? ''}. '
          '${o.xpGained > 0 ? '+${o.xpGained} XP. ' : ''}'
          '${missionDone ? 'Mission complete.' : ''}',
          style: AppText.bodyText,
        ),
        const SectionTitle('Why this matters'),
        Text(
          'A recognition model learns from many labeled, varied photos. Every record you add is one example; '
          'without a model installed, BLADNA does not predict anything — your label is the data.',
          style: AppText.bodyText,
        ),
        const SizedBox(height: 20),
        BladnaButton(
          label: 'Back to the map',
          icon: Icons.map_outlined,
          style: BladnaButtonStyle.secondary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 10),
        BladnaButton(
          label: 'Add another',
          icon: Icons.add_a_photo_outlined,
          style: BladnaButtonStyle.quiet,
          onPressed: () => setState(() {
            _saved = null;
            _path = null;
            _prediction = null;
            _category = null;
            _note.clear();
          }),
        ),
      ],
    );
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.prediction});

  final VisionPrediction? prediction;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final text = p == null
        ? 'Manual observation — no recognition model is installed in this build. Choose the category yourself.'
        : 'Model suggestion (${p.methodId}): ${p.category.label}'
            '${p.confidence == null ? '' : ' · ${(p.confidence! * 100).round()} %'}. ${p.uncertaintyNote} Confirm or correct it.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mineral.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(p == null ? Icons.edit_note_rounded : Icons.memory_rounded, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.small.copyWith(color: AppColors.ink))),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.done});

  final int n;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: done ? AppColors.restored : AppColors.midnight, shape: BoxShape.circle),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text('$n', style: AppText.data.copyWith(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: AppText.label.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}
