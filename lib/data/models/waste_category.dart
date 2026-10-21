import 'package:flutter/material.dart';

/// The sorting categories used by the game.
///
/// These are *game* categories chosen for general education. Real collection
/// streams differ between municipalities, so explanations always say when the
/// answer depends on local rules. Bin colors are BLADNA's own palette, not
/// official Tunisian bin colors.
enum WasteCategory {
  paper(
    id: 'paper',
    label: 'Paper & Cardboard',
    shortLabel: 'Paper',
    color: Color(0xFF4F86A6),
    icon: Icons.description_outlined,
  ),
  packaging(
    id: 'packaging',
    label: 'Plastic & Metal Packaging',
    shortLabel: 'Packaging',
    color: Color(0xFFD9A23C),
    icon: Icons.local_drink_outlined,
  ),
  glass(
    id: 'glass',
    label: 'Glass Bottles & Jars',
    shortLabel: 'Glass',
    color: Color(0xFF5E7A3C),
    icon: Icons.wine_bar_outlined,
  ),
  organic(
    id: 'organic',
    label: 'Organic (Compost)',
    shortLabel: 'Organic',
    color: Color(0xFF8A5A35),
    icon: Icons.eco_outlined,
  ),
  residual(
    id: 'residual',
    label: 'Residual Waste',
    shortLabel: 'Residual',
    color: Color(0xFF5B5550),
    icon: Icons.delete_outline,
  ),
  special(
    id: 'special',
    label: 'Special Drop-off',
    shortLabel: 'Special',
    color: Color(0xFFB4492E),
    icon: Icons.warning_amber_rounded,
  );

  const WasteCategory({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.icon,
  });

  final String id;
  final String label;
  final String shortLabel;
  final Color color;
  final IconData icon;

  /// A one-line description shown under each bin.
  String get hint => switch (this) {
        WasteCategory.paper => 'Clean, dry paper and flattened boxes',
        WasteCategory.packaging => 'Empty bottles, cans, tins and cartons',
        WasteCategory.glass => 'Bottles and jars only',
        WasteCategory.organic => 'Food scraps and plant waste',
        WasteCategory.residual => 'What cannot be sorted elsewhere',
        WasteCategory.special => 'Batteries, electronics, medicines',
      };

  static WasteCategory? fromId(String id) {
    for (final c in WasteCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
