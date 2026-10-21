import 'package:flutter/material.dart';

import '../models/achievement.dart';

class AchievementIds {
  static const firstSteps = 'first_steps';
  static const carefulSorter = 'careful_sorter';
  static const sharpEye = 'sharp_eye';
  static const safeHands = 'safe_hands';
  static const fieldReady = 'field_ready';
  static const eyeInTheSky = 'eye_in_the_sky';
  static const evidenceFirst = 'evidence_first';
  static const wetlandReader = 'wetland_reader';
  static const cartographer = 'cartographer';
  static const geomatician = 'geomatician';
  static const dataGardener = 'data_gardener';
}

/// Unlock conditions live in lib/domain/achievement_rules.dart.
const List<Achievement> kAchievements = [
  Achievement(id: AchievementIds.firstSteps, title: 'First Steps', description: 'Sort your first item correctly.', icon: Icons.directions_walk_rounded),
  Achievement(id: AchievementIds.carefulSorter, title: 'Careful Sorter', description: 'Learn 5 different sorting items.', icon: Icons.checklist_rounded),
  Achievement(id: AchievementIds.sharpEye, title: 'Sharp Eye', description: 'Sort 10 different items right on the first try.', icon: Icons.visibility_outlined),
  Achievement(id: AchievementIds.safeHands, title: 'Safe Hands', description: 'Route a hazardous item to special drop-off.', icon: Icons.health_and_safety_outlined),
  Achievement(id: AchievementIds.fieldReady, title: 'Field Ready', description: 'Complete Field Training in the Medina.', icon: Icons.school_outlined),
  Achievement(id: AchievementIds.eyeInTheSky, title: 'Eye in the Sky', description: 'Complete a mission played directly on the satellite map.', icon: Icons.satellite_alt_outlined),
  Achievement(id: AchievementIds.evidenceFirst, title: 'Evidence First', description: 'Answer every question of "Evidence Before Conclusions" correctly.', icon: Icons.fact_check_outlined),
  Achievement(id: AchievementIds.wetlandReader, title: 'Wetland Reader', description: 'Complete every Sebkhet Sejoumi mission.', icon: Icons.water_outlined),
  Achievement(id: AchievementIds.cartographer, title: 'Cartographer', description: 'Reveal every place on the map.', icon: Icons.travel_explore_rounded),
  Achievement(id: AchievementIds.geomatician, title: 'Young Geomatician', description: 'Complete every mission.', icon: Icons.architecture_rounded),
  Achievement(id: AchievementIds.dataGardener, title: 'Data Gardener', description: 'Save 5 field-evidence records.', icon: Icons.photo_library_outlined),
];

Achievement? achievementById(String id) {
  for (final a in kAchievements) {
    if (a.id == id) return a;
  }
  return null;
}
