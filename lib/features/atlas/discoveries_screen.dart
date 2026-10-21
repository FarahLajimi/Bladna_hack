import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_data/world_data.dart';
import '../../data/models/labeled_photo.dart';
import '../../data/models/restoration_event.dart';
import '../../data/models/waste_category.dart';
import '../../data/repositories/dataset_store.dart';
import '../../shared/components/components.dart';
import '../../state/game_controller.dart';
import '../missions/field_evidence_screen.dart';

/// My discoveries: the journal (saved events only), field-evidence records
/// and personal map annotations. Everything here can be deleted.
class DiscoveriesScreen extends StatelessWidget {
  const DiscoveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ActivityHeader(title: 'My discoveries', subtitle: 'Saved on this phone'),
              const TabBar(
                labelColor: AppColors.ink,
                indicatorColor: AppColors.action,
                tabs: [Tab(text: 'Journal'), Tab(text: 'Field evidence'), Tab(text: 'Annotations')],
              ),
              const Expanded(child: TabBarView(children: [_Journal(), _Evidence(), _Annotations()])),
            ],
          ),
        ),
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');
String _stamp(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

class _Journal extends StatelessWidget {
  const _Journal();

  static IconData _icon(RestorationEventType t) => switch (t) {
        RestorationEventType.arrival => Icons.flag_circle_outlined,
        RestorationEventType.firstSort => Icons.recycling_rounded,
        RestorationEventType.mission => Icons.task_alt_rounded,
        RestorationEventType.reveal => Icons.travel_explore_rounded,
        RestorationEventType.achievement => Icons.military_tech_outlined,
        RestorationEventType.levelUp => Icons.trending_up_rounded,
        RestorationEventType.evidence => Icons.photo_camera_outlined,
        RestorationEventType.annotation => Icons.push_pin_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final events = context.watch<GameController>().progress.events.reversed.toList();
    if (events.isEmpty) {
      return const EmptyState(title: 'Nothing yet', message: 'Your journal fills up as you investigate places on the map.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 20, color: AppColors.mineral),
      itemBuilder: (context, i) {
        final e = events[i];
        final site = e.siteId == null ? null : kSites.where((s) => s.id == e.siteId).firstOrNull;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(e.type), color: e.significant ? AppColors.action : AppColors.inkSoft, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(e.note, style: AppText.small),
                  const SizedBox(height: 4),
                  Text([_stamp(e.timestamp), if (site != null) site.name].join('  ·  '), style: AppText.data.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Evidence extends StatefulWidget {
  const _Evidence();

  @override
  State<_Evidence> createState() => _EvidenceState();
}

class _EvidenceState extends State<_Evidence> {
  String? _exported;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<GameController>().progress.fieldRecords.reversed.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Photos of real waste with YOUR label. No model is installed, so every record is a manual observation. '
          'Records keep no GPS position.',
          style: AppText.small,
        ),
        const SizedBox(height: 12),
        BladnaButton(
          label: 'New record',
          icon: Icons.add_a_photo_outlined,
          style: BladnaButtonStyle.secondary,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FieldEvidenceScreen())),
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyState(
            title: 'No records yet',
            message: 'Start the "Field Evidence" mission at Borj Chakir, or add a record here.',
            icon: Icons.photo_camera_outlined,
          )
        else ...[
          for (final r in records) _RecordRow(record: r),
          const SizedBox(height: 8),
          BladnaButton(
            label: 'Export labels.json',
            icon: Icons.ios_share_rounded,
            style: BladnaButtonStyle.quiet,
            onPressed: () async {
              final path = await DatasetStore.exportManifest(records);
              if (mounted) setState(() => _exported = path);
            },
          ),
          if (_exported != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Saved to $_exported', style: AppText.data.copyWith(fontSize: 11)),
            ),
        ],
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final LabeledPhoto record;

  @override
  Widget build(BuildContext context) {
    final cat = WasteCategory.fromId(record.categoryId);
    final mission = record.missionId == null ? null : missionById(record.missionId!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Image.file(File(record.path), fit: BoxFit.cover, cacheWidth: 200,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.mineral, child: const Icon(Icons.broken_image_outlined))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat?.label ?? record.categoryId, style: AppText.bodyStrong),
                Text(
                  record.modelPrediction == null ? 'Manual label' : 'Model: ${record.modelName} → ${record.modelPrediction}',
                  style: AppText.small.copyWith(fontSize: 12),
                ),
                if (record.note.isNotEmpty) Text('“${record.note}”', style: AppText.small.copyWith(fontSize: 12)),
                Text(mission == null ? record.location.label : 'Linked to ${mission.title} (game record)',
                    style: AppText.data.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete record',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              context.read<GameController>().removeFieldRecord(record.id);
              await DatasetStore.deletePhoto(record.path);
            },
          ),
        ],
      ),
    );
  }
}

class _Annotations extends StatelessWidget {
  const _Annotations();

  @override
  Widget build(BuildContext context) {
    final list = context.watch<GameController>().progress.annotations.reversed.toList();
    if (list.isEmpty) {
      return const EmptyState(
        title: 'No annotations yet',
        message: 'Pins you place in the Time Machine mission appear here and on the map.',
        icon: Icons.push_pin_outlined,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Positions you tapped on the imagery — user-provided, not GPS, not verified.', style: AppText.small),
        const SizedBox(height: 8),
        for (final a in list)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.push_pin_outlined),
            title: Text(a.note, style: AppText.bodyStrong),
            subtitle: Text('${a.lat.toStringAsFixed(5)}, ${a.lon.toStringAsFixed(5)} · ${missionById(a.missionId)?.title ?? ''}',
                style: AppText.data.copyWith(fontSize: 11)),
            trailing: IconButton(
              tooltip: 'Delete annotation',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => context.read<GameController>().removeAnnotation(a.id),
            ),
          ),
      ],
    );
  }
}
