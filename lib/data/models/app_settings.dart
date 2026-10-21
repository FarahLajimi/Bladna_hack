/// User preferences, stored separately from game progress so that
/// "Reset progress" keeps them.
class AppSettings {
  const AppSettings({this.haptics = true, this.reduceMotion = false});

  final bool haptics;

  /// When true, ambient animations (butterflies, shimmer) are disabled and
  /// transitions are instant. The system "remove animations" setting is also
  /// respected (see MotionPrefs).
  final bool reduceMotion;

  AppSettings copyWith({bool? haptics, bool? reduceMotion}) => AppSettings(
        haptics: haptics ?? this.haptics,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  Map<String, dynamic> toJson() => {'haptics': haptics, 'reduceMotion': reduceMotion};

  static AppSettings fromJson(Map<String, dynamic> json) => AppSettings(
        haptics: json['haptics'] is bool ? json['haptics'] as bool : true,
        reduceMotion: json['reduceMotion'] is bool ? json['reduceMotion'] as bool : false,
      );
}
