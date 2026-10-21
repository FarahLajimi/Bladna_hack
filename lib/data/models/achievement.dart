import 'package:flutter/material.dart';

/// A badge unlocked from actual game state (see AchievementRules).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}
