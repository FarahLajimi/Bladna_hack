# BLADNA — design & architecture guide

## Concept

A field instrument for reading the land. The player is an investigator over Greater Tunis: the satellite map is the world, places are clues, missions are geospatial or ecological tasks, and progress is drawn on the map itself.

## Brand

**Mark** (`assets/brand/mark.svg`, `lib/shared/widgets/brand.dart`): a survey pin whose body is a small terrain. Two irregular contour lines climb to a leaf at the summit (restoration); the orange dot under the tip is the surveyed coordinate the pin points at. One silhouette, three ideas: location, land, ecology.

- `mark.svg` — primary (midnight pin, limestone contours)
- `app_icon.svg` / `app_icon_512.png` — midnight tile, limestone pin (also the Android launcher icons in `android_overrides/`)
- `mark_mono.svg` — single color
- `logo_lockup.svg` — mark + BLADNA wordmark + "READ THE LAND · RESTORE IT"
- Splash: native midnight launch screen → Flutter splash where the contours draw in, the leaf grows and the dot lands (skipped with reduced motion).

## Color system (`lib/core/theme/app_colors.dart`)

| Role | Color | Use |
|---|---|---|
| Midnight `#0F1B2D` | primary interface, text, floating map controls |
| Limestone `#F5F1E8` / Mineral `#E6DDCB` | sheets, surfaces / dividers |
| Survey orange `#E2672B` | primary actions, map selection, open places |
| Lagoon `#2C7F8C` | secondary action, water, official figures |
| Restoration green `#4E8A4A` | completed missions, explored areas — only |
| Amber `#D99A2B` | environmental warnings, approximate zones |
| Disabled `#A9ADB3` | locked/disabled |
| Scrim `#0F1B2D` @ 70 % | overlays over imagery |

Map controls are midnight with a light hairline so they read over bright sand and dark sea. Green is reserved for restoration so it keeps its meaning. Every state also carries an icon or text.

## Typography

Space Grotesk (headings — precise, instrument-like), Inter (body), IBM Plex Mono (coordinates, measurements, map labels).

## Interaction model

- **Home = map**, edge to edge. Overlays: identity + level ring (opens the menu), search, layers, menu; a "Next" pill and a zoom-out control at the bottom.
- **Tap a place → panel** (not modal; map stays live): what you're looking at, why it matters, evidence with confidence + source, missions with state, one primary "Investigate" action. Tap empty map to close.
- **On-map missions** (trace, measure, compare dates) run in a task panel: tap the map to add points, live readout, Undo/Check, result with stars, explanation and reveals. "Back to place" returns to the same panel and camera.
- **Focused activities** (sorting, reasoning, land cover, field evidence) open full screen with a single back-to-map control; the map keeps its camera and selection.
- **Secondary destinations** live in one menu: My discoveries (journal, field evidence, annotations), Progress & achievements, Settings & account.
- Camera moves are short eased flights, only on user intent; disabled with reduced motion.

## Architecture

- `domain/game_engine.dart` scores every mission from raw inputs (polygon ring → geodesic area; two points → great-circle distance; answers; pins), grants XP only for improvement on the best stars, logs journal events, applies reveals and achievements. Pure Dart, unit-tested.
- `domain/world_rules.dart` derives revealed places, mission states and the next mission from saved progress (nothing redundant is stored).
- `data/local_data/world_data.dart` holds places, evidence (with confidence), missions (question, task, rule, learning, reference + source) and layers.
- `services/auth/auth_service.dart` is the sign-in seam; `state/session_controller.dart` keeps guest/account session (never a password).
- `domain/vision/waste_vision_model.dart` is the computer-vision seam; records store manual labels separately from any model output.
