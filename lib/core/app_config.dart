/// Build-time switches, provided at the root of the app.
class AppConfig {
  const AppConfig({this.networkTiles = true, this.showSplash = true});

  /// False in widget tests: the map renders without fetching imagery.
  final bool networkTiles;

  /// False in widget tests: skip the animated splash.
  final bool showSplash;
}
