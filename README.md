# BLADNA

**Read the land · restore it.** A map-first geospatial environmental game set in Greater Tunis — GREEN HACKATHON 2026 prototype (v0.3).

> **Validation status.** v0.1 compiled on GitHub Actions. **v0.3 is a full redesign that has not been compiled yet** — the next GitHub Actions run is its first real compile and test. It has passed the project's static checker (`tool/static_check.py`). See `DEVELOPMENT_REPORT.md`.

The map *is* the game world. You open the app onto real satellite imagery of Greater Tunis, discover a place, inspect it, investigate it (trace, measure, compare dates, reason, collect field evidence), learn why it matters — and that reveals the next place.

**Loop:** Discover → Inspect → Interpret → Act → Learn → Reveal

| Place (real) | Missions | Reveals |
|---|---|---|
| **Medina of Tunis** (start) | Field Training — waste-sorting game (learn 5 items) | Borj Chakir |
| **Borj Chakir** (landfill area, *approximate*) | Where Does It Go? (measure distance) · Name the Facility (landfill vs dumpsite vs collection point vs recycling facility) · Field Evidence (photo + manual label) | Sebkhet Sejoumi |
| **Sebkhet Sejoumi** (Ramsar wetland) | The Wetland Next Door (trace area) · Evidence Before Conclusions (reasoning) · Time Machine: The Shore (2016 ↔ 2024 swipe; pins become annotations) | Lake of Tunis |
| **Lake of Tunis** (Ramsar lagoon) | Trace the Lake (area) · Read the Land (land-cover interpretation) | — |

The map shows progress: unrevealed places are muted "?" clues, open places pulse in survey orange, completed places turn restoration green with an explored halo, a trail links each place to the one that revealed it, and your own Time Machine pins appear as annotations.

---

## What is implemented vs. not

| | Status |
|---|---|
| Map-first explore screen (satellite / streets / Sentinel-2 2016 & 2024 / swipe compare), search, layer menu, contextual place panels, camera flights | **Implemented** — imagery needs internet |
| 10 missions scored from raw inputs (area, distance, answers), improvement-only XP, reveals, journal | **Implemented** — offline |
| Field Evidence: camera/gallery, review, manual label, note, mission link, local storage, delete, `labels.json` export | **Implemented** — offline |
| Waste-sorting mini-game (29 items) as Field Training | **Implemented** — offline |
| Achievements (11), levels, progress screen, settings, reset | **Implemented** — offline |
| Sign-in / create account / password reset screens with validation | **UI implemented; provider NOT configured** — every account call says so. Players use a labelled **guest** profile. See `docs/FIREBASE_SETUP.md`. |
| Progress sync across devices | **Not implemented** (progress is local only) |
| AI waste recognition (Litter Lens) | **Planned, not implemented.** `WasteVisionModel` interface + honest `NoModelYet`; no prediction is ever shown. |
| Satellite dump/encroachment detection (Sky Scan) | **Planned, not implemented.** |
| Land-cover map layer (ESA WorldCover) | **Planned, not connected** (tile endpoint not verified). No land-cover colors are invented. |

## Real data vs. game data

- **Verified / sourced:** place coordinates, areas and facts. Each fact shows its confidence: *official figure*, *documented*, *reported*, *approximate location*. Borj Chakir is drawn as an **approximate 1.5 km area** around a locality coordinate — never as a landfill boundary.
- **Educational examples:** the three "Read the Land" views are centered on documented places; answers describe what dominates the view.
- **Game data:** stars, XP, revealed places, explored halos, trails — learning progress, not real-world environmental improvement.
- **User data (local only):** map annotations (positions you tapped — not GPS) and field-evidence photos with manual labels. No GPS is ever read.

## Data sources

- Ramsar Sites Information Service — Sebkhet Sejoumi (site 1712): https://rsis.ramsar.org/ris/1712 (Ramsar since 7 Nov 2007, 2,979 ha, seasonal salt lake, waterbirds; threats incl. shore construction around Sidi Hassine, untreated wastewater, waste dumping)
- Wikipedia — Lake of Tunis (≈37 km², Ramsar 2013, Chikly 1993): https://en.wikipedia.org/wiki/Lake_of_Tunis · Medina of Tunis (UNESCO 1979, ≈296 ha): https://en.wikipedia.org/wiki/Medina_of_Tunis · Al-Zaytuna Mosque (36.7972 N, 10.1711 E): https://en.wikipedia.org/wiki/Al-Zaytuna_Mosque
- Nawaat (2015) — Borj Chakir landfill (opened 1999, ≈120 ha, 2,700–3,000 t/day, reported concerns): https://nawaat.org/2015/05/17/the-landfill-at-borj-chakir-a-serious-threat-to-a-decent-life-and-clean-environment/
- satellites.pro — Borj Chakir locality coordinate: https://satellites.pro/Borj_Chakir_map
- Imagery: Esri World Imagery (Esri, Maxar, Earthstar Geographics, and the GIS User Community — review Esri terms before any public release) · EOxCloudless Sentinel-2 by EOX IT Services GmbH, contains modified Copernicus Sentinel data — 2016 layer CC BY 4.0, 2024 layer CC BY-NC-SA 4.0 (non-commercial): https://cloudless.eox.at · OpenStreetMap standard tiles © OpenStreetMap contributors (light use only, per the OSM tile usage policy).

## Build & install (no Flutter needed on your PC)

GitHub Actions builds the APK (`.github/workflows/build-apk.yml`): it generates the Android folder with the current stable Flutter, applies the BLADNA launcher icon and native splash from `android_overrides/`, runs `flutter pub get`, `flutter analyze`, `flutter test`, and uploads `app-debug.apk` as the **bladna-apk** artifact.

With Flutter installed locally:

```bash
flutter create --platforms=android --project-name bladna --org tn.greenhackathon2026 .   # first time only
cp -r android_overrides/* android/
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

## Project structure

```
lib/
  app.dart, main.dart            providers; splash → sign-in → map
  core/                          theme (colors, type), rules, config, motion
  data/models/                   world (places, missions, evidence), progress (schema 2), records, annotations
  data/local_data/               world_data (places, missions, layers), waste items, achievements
  data/repositories/             progress (v1 → v2 migration), dataset store (photos)
  domain/                        game_engine, world_rules, geodesy, achievement_rules, vision/
  services/auth/                 AuthService seam + honest UnconfiguredAuthService
  state/                         GameController, SessionController
  features/
    splash/  auth/  explore/     the map, markers, place panel, layer/search/menu sheets
    missions/                    quiz, land cover, field evidence, result view
    sorting_game/  atlas/  settings/
  shared/                        components, brand (logo painter), contour motif
assets/brand/                    logo SVGs and app icon
assets/fonts/                    Space Grotesk, Inter, IBM Plex Mono (SIL OFL)
android_overrides/               launcher icons + native splash copied over the generated android/ folder
docs/                            DESIGN.md (design & architecture), FIREBASE_SETUP.md
test/                            engine, content, geodesy, persistence & session, widgets
```

## Tests

`engine_test` (sorting XP, Field Training, locking, distance vs area scoring, improvement-only XP, Time Machine annotations, quizzes, land cover, field evidence, full exploration) · `content_test` (sources, coordinates, reachability, one correct answer per question, HTTPS layers) · `geodesy_test` · `persistence_and_session_test` (round trip, v1 migration, corrupt saves, reset, guest session, sign-out keeps progress, no passwords stored) · `widget_test` (sign-in is the entry point, guest → map, place panel, mission → back to the same place).

## Safety

Field Evidence asks for safe items only (no broken glass, needles, chemicals or people). Missions never require visiting a site. Sorting answers are general examples — check local municipal guidance.

## Credits

Built for GREEN HACKATHON 2026 by a Geospatial Informatics Engineering student and an Ecological Engineering student, with team contributors. Fonts under SIL OFL 1.1 (`assets/fonts/`).
#   B l a d n a _ h a c k  
 