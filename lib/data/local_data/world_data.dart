import 'package:latlong2/latlong.dart';

import '../models/world.dart';

/// The playable world: four REAL places in Greater Tunis and ten missions.
///
/// Sources (full URLs in README → Data sources):
/// - Ramsar Information Sheet 1712 — Sebkhet Sejoumi (36°45′N 10°09′E, 2,979 ha, threats).
/// - Wikipedia — Lake of Tunis (36°49′N 10°15′E, ≈37 km², Ramsar 2013, Chikly 1993),
///   Medina of Tunis (UNESCO 1979, ≈296 ha), Al-Zaytuna Mosque (36.7972 N, 10.1711 E).
/// - Nawaat (2015) — Borj Chakir landfill (opened 1999, ≈120 ha, 2,700–3,000 t/day).
/// - satellites.pro — Borj Chakir LOCALITY coordinate 36°45′29″N 10°04′41″E.
///   This is not a surveyed landfill boundary; the app draws an approximate area.
class SiteIds {
  static const medina = 'medina';
  static const borjChakir = 'borj_chakir';
  static const sejoumi = 'sebkhet_sejoumi';
  static const lake = 'lake_tunis';

  static const all = [medina, borjChakir, sejoumi, lake];
}

class MissionIds {
  static const fieldTraining = 'field_training';
  static const wasteRoute = 'waste_route';
  static const nameTheFacility = 'name_the_facility';
  static const fieldEvidence = 'field_evidence';
  static const traceSejoumi = 'trace_sejoumi';
  static const evidenceFirst = 'evidence_first';
  static const shoreChange = 'shore_change';
  static const traceLake = 'trace_lake';
  static const readTheLand = 'read_the_land';
}

const LatLng kTunisCenter = LatLng(36.785, 10.15);
const double kTunisZoom = 11.2;

const List<RealSite> kSites = [
  RealSite(
    id: SiteIds.medina,
    name: 'Medina of Tunis',
    arabicName: 'مدينة تونس',
    center: LatLng(36.7972, 10.1711),
    kind: 'Historic city · UNESCO World Heritage',
    focusZoom: 15,
    lookingAt:
        'A tight mosaic of flat roofs and inner courtyards around the Al-Zaytuna Mosque — the old city, built densely over centuries.',
    whyItMatters:
        'Everything that happens to waste later — collection, recycling, landfill — starts with how it is sorted at home. Dense neighborhoods are where that habit matters most.',
    evidence: [
      Evidence('Marker placed on the Al-Zaytuna Mosque (36.7972 N, 10.1711 E).', 'Wikipedia', Confidence.documented),
      Evidence('Inscribed on the UNESCO World Heritage List in 1979.', 'Wikipedia', Confidence.documented),
      Evidence('The Medina and Kasbah cover about 296 ha.', 'Wikipedia', Confidence.documented),
    ],
  ),
  RealSite(
    id: SiteIds.borjChakir,
    name: 'Borj Chakir',
    arabicName: 'برج شاكر',
    center: LatLng(36.7581, 10.0781),
    kind: 'Landfill area of Greater Tunis',
    focusZoom: 13.5,
    approximate: true,
    approxRadiusMeters: 1500,
    revealedBy: [MissionIds.fieldTraining],
    revealHint: 'Finish Field Training in the Medina to find out where the city\'s waste goes.',
    lookingAt:
        'South-west of the city, on former farmland: the area of Borj Chakir, home of Greater Tunis\'s controlled landfill. The circle is approximate — the landfill boundary is not mapped here.',
    whyItMatters:
        'Where waste ends up decides what happens to the air, soil and groundwater around it. A landfill is engineered to contain waste — and it only protects its neighbors if it is well run.',
    evidence: [
      Evidence('Opened in 1999 on about 120 ha of former farmland.', 'Nawaat, 2015', Confidence.reported),
      Evidence('Receives waste from Tunis, Ariana, Ben Arous and Manouba: 2,700–3,000 t per day.', 'Nawaat, 2015',
          Confidence.reported),
      Evidence('Residents and activists reported odors, leachate and groundwater concerns.', 'Nawaat, 2015',
          Confidence.reported),
      Evidence('Pin = Borj Chakir locality coordinate, drawn with a 1.5 km circle.', 'satellites.pro',
          Confidence.approximate),
    ],
  ),
  RealSite(
    id: SiteIds.sejoumi,
    name: 'Sebkhet Sejoumi',
    arabicName: 'سبخة السيجومي',
    center: LatLng(36.75, 10.15),
    kind: 'Seasonal salt lake · Ramsar wetland',
    focusZoom: 12.6,
    revealedBy: [MissionIds.wasteRoute, MissionIds.nameTheFacility],
    revealHint: 'Investigate Borj Chakir: the Ramsar sheet of a nearby wetland mentions waste dumping.',
    lookingAt:
        'A wide, pale basin south-west of the city: a shallow salt lake. It fills in winter; in summer much of it dries into salt flats and mud.',
    whyItMatters:
        'Wetlands like this are feeding and resting grounds for waterbirds — flamingos, ducks and waders winter here. Construction, untreated wastewater and dumping all press on its shores.',
    evidence: [
      Evidence('Ramsar Site 1712 since 7 November 2007, 2,979 ha.', 'Ramsar RIS 1712', Confidence.official),
      Evidence('Shallow closed salt lake: fills in winter, largely dries in summer.', 'Ramsar RIS 1712',
          Confidence.documented),
      Evidence('Hosts large numbers of flamingos, ducks and waders; an Important Bird Area.', 'Ramsar RIS 1712',
          Confidence.documented),
      Evidence(
          'Threats listed: construction encroaching on the shores (especially around Sidi Hassine), untreated wastewater, waste dumping.',
          'Ramsar RIS 1712',
          Confidence.documented),
    ],
  ),
  RealSite(
    id: SiteIds.lake,
    name: 'Lake of Tunis',
    arabicName: 'بحيرة تونس',
    center: LatLng(36.817, 10.25),
    kind: 'Coastal lagoon · Ramsar wetland',
    focusZoom: 12,
    revealedBy: [MissionIds.traceSejoumi, MissionIds.evidenceFirst],
    revealHint: 'Read Sejoumi first — then follow the water to the coast.',
    lookingAt: 'A large coastal lagoon between Tunis and the Gulf of Tunis, crossed by a causeway.',
    whyItMatters:
        'Lagoons connect the city to the sea. What runs off streets and drains ends up here — which is why the lake is now protected as a wetland.',
    evidence: [
      Evidence('About 37 km².', 'Wikipedia', Confidence.documented),
      Evidence('Designated a Ramsar wetland on 23 January 2013.', 'Wikipedia', Confidence.documented),
      Evidence('Chikly island in the lake has been a nature reserve since 1993.', 'Wikipedia', Confidence.documented),
    ],
  ),
];

const List<Mission> kMissions = [
  // ------------------------------------------------------------- Medina
  Mission(
    id: MissionIds.fieldTraining,
    siteId: SiteIds.medina,
    title: 'Field Training',
    type: MissionType.sorting,
    question: 'Which bin does each everyday item belong in — and why?',
    task: 'Play the sorting game and learn 5 different items.',
    rule: 'Completed when 5 different items are learned (sorted correctly at least once): 3★.',
    learning:
        'Clean, separated materials can be recycled; mixed or soiled ones usually cannot. Rules differ by municipality, so check local guidance.',
  ),
  // -------------------------------------------------------- Borj Chakir
  Mission(
    id: MissionIds.wasteRoute,
    siteId: SiteIds.borjChakir,
    title: 'Where Does It Go?',
    type: MissionType.measure,
    question: 'How far does a bag of household waste travel from the old city to disposal?',
    task: 'Tap the Medina, then the Borj Chakir area. BLADNA measures the straight-line (great-circle) distance.',
    rule: 'Compared with the reference: within 15 % → 3★, 30 % → 2★, 50 % → 1★.',
    learning:
        'Straight-line distance is only a first estimate — trucks drive farther on real roads. Distance to disposal is a major cost in waste planning.',
    referenceLabel: 'Zaytuna Mosque → Borj Chakir locality',
    referenceSource: 'Coordinates: Wikipedia, satellites.pro',
    referenceKind: Confidence.approximate,
    focusZoom: 11.6,
  ),
  Mission(
    id: MissionIds.nameTheFacility,
    siteId: SiteIds.borjChakir,
    title: 'Name the Facility',
    type: MissionType.quiz,
    question: 'A landfill, a dumpsite, a collection point and a recycling facility are not the same thing. Which is which?',
    task: 'Answer four short questions.',
    rule: 'All correct → 3★, three → 2★, two → 1★.',
    learning:
        'Borj Chakir is described as a controlled landfill — and the same report describes leachate and odor problems. "Controlled" is a design, not a guarantee.',
    quiz: [
      QuizQuestion(
        prompt: 'An engineered site that receives waste and is meant to contain it for the long term — with liners, leachate collection and gas management.',
        options: [
          QuizOption('Controlled landfill', correct: true),
          QuizOption('Uncontrolled dumpsite'),
          QuizOption('Collection point'),
          QuizOption('Recycling facility'),
        ],
        explanation: 'A controlled (sanitary) landfill is designed to isolate waste from soil, water and air.',
      ),
      QuizQuestion(
        prompt: 'Waste left on open land, a riverbank or a wetland edge, without permits or any containment.',
        options: [
          QuizOption('Controlled landfill'),
          QuizOption('Uncontrolled dumpsite', correct: true),
          QuizOption('Collection point'),
          QuizOption('Recycling facility'),
        ],
        explanation: 'Uncontrolled dumping has no protection at all — rain carries pollution straight into soil and water.',
      ),
      QuizQuestion(
        prompt: 'A spot in the neighborhood where residents leave their bags or sorted materials for pickup.',
        options: [
          QuizOption('Controlled landfill'),
          QuizOption('Uncontrolled dumpsite'),
          QuizOption('Collection point', correct: true),
          QuizOption('Recycling facility'),
        ],
        explanation: 'Collection points are the first link of the chain — waste is only stored there briefly.',
      ),
      QuizQuestion(
        prompt: 'A plant where separated materials are processed so they can be made into new products.',
        options: [
          QuizOption('Controlled landfill'),
          QuizOption('Uncontrolled dumpsite'),
          QuizOption('Collection point'),
          QuizOption('Recycling facility', correct: true),
        ],
        explanation: 'Recycling only works if materials arrive clean and separated — which is why sorting at home matters.',
      ),
    ],
  ),
  Mission(
    id: MissionIds.fieldEvidence,
    siteId: SiteIds.borjChakir,
    title: 'Field Evidence',
    type: MissionType.fieldEvidence,
    requires: [MissionIds.nameTheFacility],
    question: 'What would a computer need in order to learn to recognize waste?',
    task:
        'Photograph one real waste item at home (only safe items — no broken glass, needles, chemicals or people), confirm its category yourself and add a note.',
    rule: 'Completed when one record is saved: 3★.',
    learning:
        'Models learn from labeled examples. Your manual label is the "ground truth". With many varied records a detector could be trained later — no model is installed in this build.',
  ),
  // ------------------------------------------------------ Sebkhet Sejoumi
  Mission(
    id: MissionIds.traceSejoumi,
    siteId: SiteIds.sejoumi,
    title: 'The Wetland Next Door',
    type: MissionType.digitize,
    question: 'Where does the wetland end and the city begin?',
    task: 'Tap around the edge of the sebkha (the pale salt flat and its water), then press Check.',
    rule: 'Your traced AREA is compared with the Ramsar site area: within 15 % → 3★, 30 % → 2★, 50 % → 1★.',
    learning:
        'An official site boundary is not the same as the water you see: the Ramsar site includes shores and mudflats, and the water shrinks every summer.',
    referenceValue: 2979e4,
    referenceLabel: '2,979 ha (Ramsar site area)',
    referenceSource: 'Ramsar RIS 1712',
    referenceKind: Confidence.official,
  ),
  Mission(
    id: MissionIds.evidenceFirst,
    siteId: SiteIds.sejoumi,
    title: 'Evidence Before Conclusions',
    type: MissionType.quiz,
    question: 'What can — and can\'t — a satellite image tell us about a wetland?',
    task: 'Answer three questions about reading Sejoumi responsibly.',
    rule: 'All correct → 3★, two → 2★.',
    learning:
        'Imagery shows that land cover changed. Judging ecological harm needs more: field visits, bird and water surveys, same-season images and official records.',
    quiz: [
      QuizQuestion(
        prompt: 'A 2024 image shows new buildings near the shore that were not there in 2016. What can you conclude?',
        options: [
          QuizOption('The wetland is destroyed.'),
          QuizOption(
              'Land cover changed at those spots. To judge ecological impact we need more evidence: field visits, surveys, same-season images, official records.',
              correct: true),
          QuizOption('Nothing — satellite images cannot show change.'),
        ],
        explanation: 'Change detection tells you WHERE to look closer, not the full story.',
      ),
      QuizQuestion(
        prompt: 'In summer, much of Sejoumi\'s visible water disappears. Is that, on its own, a sign of degradation?',
        options: [
          QuizOption('Yes — the lake is drying up.'),
          QuizOption('No — it is a seasonal salt lake that naturally dries in summer; compare images from the same season.',
              correct: true),
        ],
        explanation: 'The Ramsar sheet describes Sejoumi as filling in winter and largely drying in summer.',
      ),
      QuizQuestion(
        prompt: 'Why is Sebkhet Sejoumi listed as a Ramsar wetland of international importance?',
        options: [
          QuizOption('It is a freshwater reservoir for drinking water.'),
          QuizOption('It supports large numbers of waterbirds such as flamingos, ducks and waders.', correct: true),
          QuizOption('It is a protected forest.'),
        ],
        explanation: 'Its birds are the main reason it is an Important Bird Area and a Ramsar site.',
      ),
    ],
  ),
  Mission(
    id: MissionIds.shoreChange,
    siteId: SiteIds.sejoumi,
    title: 'Time Machine: The Shore',
    type: MissionType.timeMachine,
    requires: [MissionIds.evidenceFirst],
    question: 'What changed on Sejoumi\'s shore between 2016 and 2024?',
    task: 'Swipe between the 2016 and 2024 Sentinel-2 mosaics and pin 3 places where you see change.',
    rule: 'Completed with 3 pins: 3★. Pins are your interpretation, not verified facts.',
    learning:
        'Both layers are annual cloud-free Sentinel-2 mosaics (10 m pixels) from the same provider, so they can be compared — but differences can also come from season and mosaic processing.',
    markersNeeded: 3,
    focusZoom: 13,
  ),
  // -------------------------------------------------------- Lake of Tunis
  Mission(
    id: MissionIds.traceLake,
    siteId: SiteIds.lake,
    title: 'Trace the Lake',
    type: MissionType.digitize,
    question: 'How big is the lagoon that links Tunis to the sea?',
    task: 'Tap around the outer shoreline of the whole lake (both basins), then press Check.',
    rule: 'Your traced AREA is compared with the reference: within 15 % → 3★, 30 % → 2★, 50 % → 1★.',
    learning:
        'You digitized a polygon. Its area is computed on the curved Earth (spherical excess) — the same idea GIS software uses.',
    referenceValue: 37e6,
    referenceLabel: '≈ 37 km²',
    referenceSource: 'Wikipedia (Lake of Tunis)',
    referenceKind: Confidence.documented,
  ),
  Mission(
    id: MissionIds.readTheLand,
    siteId: SiteIds.lake,
    title: 'Read the Land',
    type: MissionType.landCover,
    question: 'What covers the ground here?',
    task: 'Three views, each centered on a documented place. Choose the land cover that dominates each view.',
    rule: '1★ for each correct answer.',
    learning:
        'Photo-interpretation uses color, texture, shape and context. Land cover can change with the seasons — Sejoumi can look like open water in winter and bare salt flat in summer.',
    landCover: [
      LandCoverExample(
        point: LatLng(36.817, 10.25),
        answer: LandCoverClass.water,
        explanation: 'Open water of the Lake of Tunis — smooth, uniform, dark.',
        source: 'Lake coordinates: Wikipedia',
      ),
      LandCoverExample(
        point: LatLng(36.7972, 10.1711),
        answer: LandCoverClass.builtUp,
        explanation: 'The dense Medina around the Al-Zaytuna Mosque — a fine, bright texture of roofs.',
        source: 'Mosque coordinates: Wikipedia',
      ),
      LandCoverExample(
        point: LatLng(36.75, 10.15),
        answer: LandCoverClass.wetland,
        explanation: 'Sebkhet Sejoumi: a seasonal salt lake. It is a wetland even when it looks dry and pale.',
        source: 'Ramsar RIS 1712 coordinates',
      ),
    ],
  ),
];

RealSite siteById(String id) => kSites.firstWhere((s) => s.id == id, orElse: () => kSites.first);

Mission? missionById(String id) {
  for (final m in kMissions) {
    if (m.id == id) return m;
  }
  return null;
}

List<Mission> missionsAt(String siteId) => kMissions.where((m) => m.siteId == siteId).toList();

/// Imagery and reference layers. Attribution follows each provider's terms.
class Basemap {
  const Basemap({
    required this.id,
    required this.label,
    required this.urlTemplate,
    required this.attribution,
    required this.maxNativeZoom,
    required this.detail,
  });

  final String id;
  final String label;
  final String urlTemplate;
  final String attribution;
  final int maxNativeZoom;

  /// Date and nature of the source, shown in the layer menu.
  final String detail;
}

const kBasemapEsri = Basemap(
  id: 'esri',
  label: 'Satellite',
  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  attribution: 'Imagery: Esri, Maxar, Earthstar Geographics, and the GIS User Community',
  maxNativeZoom: 19,
  detail: 'Esri World Imagery · mosaic of recent aerial & satellite images, sub-metre in cities; dates vary by area',
);

const kBasemapOsm = Basemap(
  id: 'osm',
  label: 'Streets',
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution: '© OpenStreetMap contributors',
  maxNativeZoom: 19,
  detail: 'OpenStreetMap · community reference map (roads, names, land use)',
);

const kBasemapS2024 = Basemap(
  id: 's2_2024',
  label: 'Sentinel-2 2024',
  urlTemplate: 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2024_3857/default/GoogleMapsCompatible/{z}/{y}/{x}.jpg',
  attribution:
      'EOxCloudless 2024 — cloudless.eox.at by EOX IT Services GmbH (Contains modified Copernicus Sentinel data 2024)',
  maxNativeZoom: 15,
  detail: 'Copernicus Sentinel-2 · cloud-free annual mosaic 2024 · 10 m pixels',
);

const kBasemapS2016 = Basemap(
  id: 's2_2016',
  label: 'Sentinel-2 2016',
  urlTemplate: 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless_3857/default/GoogleMapsCompatible/{z}/{y}/{x}.jpg',
  attribution:
      'EOxCloudless 2016 — cloudless.eox.at by EOX IT Services GmbH (Contains modified Copernicus Sentinel data 2016 & 2017)',
  maxNativeZoom: 15,
  detail: 'Copernicus Sentinel-2 · cloud-free mosaic 2016–17 · 10 m pixels',
);

const kBasemaps = [kBasemapEsri, kBasemapOsm, kBasemapS2024, kBasemapS2016];
