# BLADNA — development report

## v0.3 redesign (21 October 2026)

### What changed
- **Product:** from a fictional-neighborhood game with tabs to a **map-first** game over real Greater Tunis. The illustrated "Butterfly Block", its zones, mission chain, tab bar, Eco Map, Memory and AI Lab screens were retired (team decision); the waste-sorting game was kept as the Medina's *Field Training* mission.
- **Brand:** new logo (contour pin with leaf summit and coordinate dot) as SVGs, a Flutter painter, app icon, monochrome version, Android launcher icons and native + animated splash. New palette (midnight, limestone, survey orange, lagoon, restoration green, amber) and type (Space Grotesk, Inter, IBM Plex Mono). Grid-paper, stamps, handwriting and heavy card styling removed.
- **Explore screen:** full-screen map with floating controls, search, layer menu (satellite, streets, Sentinel-2 2016/2024, swipe compare), contextual place panel with evidence + confidence labels, on-map task panel, eased camera flights, progress drawn on the map (hidden/open/explored places, halos, trail, annotations).
- **Missions:** 10 missions across 4 real places with a reveal chain. Scoring computed from raw inputs in the engine: geodesic area (trace), great-circle distance (measure), answers (quiz), classes (land cover), pins (time machine). XP only for improvement. Reveals logged in the journal.
- **Field Evidence** (computer-vision data collection) integrated as a Borj Chakir mission; records hold manual label, note, optional mission link, location kind (none / mission link — never GPS), and a separate slot for real model output (always empty in this build).
- **Sign-in:** welcome, sign in, create account, password reset, validation, loading and error states; `AuthService` seam with an honest `UnconfiguredAuthService`; guest session; sign-out keeps local progress. Firebase steps in `docs/FIREBASE_SETUP.md`.
- **Persistence:** progress schema 2 with migration from schema 1 (XP, learned items, kept achievements, journal, Sky Lab stars, photos).

### Commands actually executed (in Claude's workspace)
- `npm pack @expo-google-fonts/{space-grotesk,inter,ibm-plex-mono}` → fonts + OFL licenses.
- `pip install cairosvg`; Python/cairosvg rendering of the logo SVGs → previews inspected visually; launcher PNGs (48–192 px) and a 512 px icon generated.
- Python numeric cross-checks of the geodesy formulas and of the test fixtures (square rings within 0.001 % of the reference areas; the "far" measure point gives 96 % error → 0★).
- `python3 tool/static_check.py . bladna` → **passes** (57 Dart files: imports resolve, brackets balance, every project symbol is imported, enum values/static members exist, no unused relative imports).
- Web research to verify: flutter_map 8.3.2 constructors (FlutterMap `mapController`, `TapCallback(tapPosition, point)`, Marker, Polygon, Polyline, CircleMarker, TileLayer, MapController.move/camera/dispose), EOX WMTS layer names, Ramsar/Wikipedia/Nawaat facts.

### Not executed
`flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, `flutter build apk` — Flutter cannot be installed in this workspace (download host blocked). **No compile, test or build result exists for v0.3.** The GitHub Actions workflow runs all of them.

### Known risks
- First compile of a large rewrite: expect a few analyzer errors to fix.
- `RadioListTile.groupValue` may show a deprecation info on the newest Flutter (not an error).
- Map layout details (marker label overlap at low zoom, panel heights on very small phones) need a check on a device.
- Esri imagery terms must be reviewed before any public or commercial release; OSM tiles are for light use only.
- The ESA WorldCover layer is not connected (endpoint unverified) and is labelled as planned.

### Remaining tasks
1. Upload v0.3, run the workflow, fix analyzer/test failures.
2. Test on a small Android phone and with large font sizes.
3. Ecological engineer: review mission texts and the sorting explanations against local guidance.
4. Optional: configure Firebase (docs/FIREBASE_SETUP.md); connect a verified land-cover layer; train a Litter Lens model from field-evidence records.

---

## History
- v0.1 — Butterfly Block prototype (compiled on GitHub Actions).
- v0.2 — Field-notebook theme, Sky Lab satellite quests, AI Lab (not separately confirmed to compile).
- v0.3 — this redesign.
