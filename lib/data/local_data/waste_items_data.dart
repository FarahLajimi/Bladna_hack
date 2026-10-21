import '../models/waste_category.dart';
import '../models/waste_item.dart';

/// Sorting content. General educational examples — the team should validate
/// them against current municipal guidance before any public release.
/// Items flagged [WasteItem.dependsOnLocalRules] tell the player to check
/// local collection rules.
const List<WasteItem> kWasteItems = [
  // ---------- Plastic & metal packaging ----------
  WasteItem(
    id: 'plastic_bottle',
    name: 'Plastic water bottle',
    category: WasteCategory.packaging,
    shape: ItemShape.bottle,
    zoneId: 'street',
    explanation:
        'Empty plastic drink bottles are among the most widely collected packaging. Empty it and squash it to save space.',
    mistakeHint: 'It is light and plastic — think packaging, not residual.',
  ),
  WasteItem(
    id: 'soda_can',
    name: 'Aluminium drink can',
    category: WasteCategory.packaging,
    shape: ItemShape.can,
    zoneId: 'street',
    explanation:
        'Aluminium can be recycled again and again without losing quality. Empty it first.',
  ),
  WasteItem(
    id: 'tomato_tin',
    name: 'Tomato paste tin',
    category: WasteCategory.packaging,
    shape: ItemShape.tin,
    zoneId: 'street',
    explanation:
        'Steel food tins are metal packaging. A quick rinse avoids smells in the bin.',
    safetyNote: 'Cut lids can be sharp — press the lid gently inside the tin, or ask an adult.',
  ),
  WasteItem(
    id: 'yogurt_pot',
    name: 'Yogurt pot',
    category: WasteCategory.packaging,
    shape: ItemShape.yogurtPot,
    dependsOnLocalRules: true,
    explanation:
        'In this game small plastic pots go with packaging. Some real collection schemes only accept bottles, so check what your municipality accepts.',
  ),
  WasteItem(
    id: 'detergent_bottle',
    name: 'Empty detergent bottle',
    category: WasteCategory.packaging,
    shape: ItemShape.detergent,
    explanation:
        'Once empty, a rigid plastic bottle is packaging. Leave the cap on so it does not get lost.',
    mistakeHint:
        'It held a cleaning product, but an empty bottle is not special waste — it is plastic packaging.',
  ),
  WasteItem(
    id: 'juice_carton',
    name: 'Juice carton',
    category: WasteCategory.packaging,
    shape: ItemShape.juiceCarton,
    dependsOnLocalRules: true,
    explanation:
        'Drink cartons are layers of paper, plastic and aluminium. Many schemes collect them with packaging, but not all — check locally.',
    mistakeHint:
        'It looks like paper, but the hidden plastic and aluminium layers keep it out of the paper stream.',
  ),

  // ---------- Paper & cardboard ----------
  WasteItem(
    id: 'newspaper',
    name: 'Old newspaper',
    category: WasteCategory.paper,
    shape: ItemShape.newspaper,
    zoneId: 'market',
    explanation: 'Clean, dry newspaper is one of the easiest materials to recycle.',
  ),
  WasteItem(
    id: 'cardboard_box',
    name: 'Delivery cardboard box',
    category: WasteCategory.paper,
    shape: ItemShape.box,
    zoneId: 'market',
    explanation:
        'Flatten boxes so they take less space, and peel off plastic tape where you can.',
  ),
  WasteItem(
    id: 'bread_bag',
    name: 'Paper baguette bag',
    category: WasteCategory.paper,
    shape: ItemShape.paperBag,
    zoneId: 'market',
    explanation:
        'A clean, dry paper bag goes with paper. If it is greasy or wet, it belongs with residual waste instead.',
  ),
  WasteItem(
    id: 'egg_carton',
    name: 'Cardboard egg box',
    category: WasteCategory.paper,
    shape: ItemShape.eggCarton,
    explanation:
        'Moulded cardboard egg boxes go with paper. Small torn pieces can also be added to a home compost.',
  ),
  WasteItem(
    id: 'pizza_box',
    name: 'Greasy pizza box',
    category: WasteCategory.residual,
    shape: ItemShape.pizzaBox,
    zoneId: 'square',
    explanation:
        'Grease and cheese spoil paper recycling. Tear off any clean lid for paper; the greasy part goes to residual waste.',
    mistakeHint: 'It is cardboard — but grease contaminates the paper stream.',
  ),

  // ---------- Glass ----------
  WasteItem(
    id: 'harissa_jar',
    name: 'Harissa glass jar',
    category: WasteCategory.glass,
    shape: ItemShape.jar,
    zoneId: 'courtyard',
    explanation:
        'Glass jars can be melted and remade many times. Empty it and take off the metal lid — the lid goes with packaging.',
  ),
  WasteItem(
    id: 'oil_bottle',
    name: 'Olive oil glass bottle',
    category: WasteCategory.glass,
    shape: ItemShape.glassBottle,
    zoneId: 'courtyard',
    explanation:
        'Glass bottles belong with glass. Some bottles can even be returned to the shop for reuse — ask where you buy.',
  ),
  WasteItem(
    id: 'jam_jar',
    name: 'Fig jam jar',
    category: WasteCategory.glass,
    shape: ItemShape.jar,
    zoneId: 'courtyard',
    explanation:
        'Another glass jar! Or give it a second life first — jars make good spice pots and seed holders.',
  ),
  WasteItem(
    id: 'broken_glass',
    name: 'Broken drinking glass',
    category: WasteCategory.residual,
    shape: ItemShape.brokenGlass,
    explanation:
        'Drinking glasses are made differently from bottle glass and melt at a different temperature, so they do not go with bottles and jars.',
    mistakeHint: 'Not all glass is the same — only bottles and jars go in the glass bank.',
    safetyNote:
        'Never pick up broken glass with bare hands. Ask an adult to wrap it in thick paper and label it before binning.',
  ),
  WasteItem(
    id: 'mirror',
    name: 'Small cracked mirror',
    category: WasteCategory.residual,
    shape: ItemShape.mirror,
    explanation:
        'Mirrors have a metal coating that glass recyclers cannot accept. It goes with residual waste.',
    mistakeHint: 'Mirrors look like glass, but their coating keeps them out of the glass bank.',
    safetyNote: 'Handle cracked mirrors with gloves and wrap the edges first — or ask an adult.',
  ),
  WasteItem(
    id: 'ceramic_plate',
    name: 'Broken ceramic plate',
    category: WasteCategory.residual,
    shape: ItemShape.plate,
    explanation:
        'Ceramics are not glass. Even small pieces can spoil a batch of recycled glass, so they go to residual waste.',
    mistakeHint: 'It is shiny and hard, but ceramic is not glass.',
    safetyNote: 'Sharp edges: wrap the pieces in paper before binning, or ask an adult.',
  ),

  // ---------- Organic ----------
  WasteItem(
    id: 'orange_peel',
    name: 'Orange peels',
    category: WasteCategory.organic,
    shape: ItemShape.peel,
    zoneId: 'garden',
    explanation: 'Peels break down into compost that feeds the soil of the garden.',
  ),
  WasteItem(
    id: 'veg_scraps',
    name: 'Couscous vegetable trimmings',
    category: WasteCategory.organic,
    shape: ItemShape.scraps,
    zoneId: 'garden',
    explanation:
        'Carrot tops, squash skins and turnip ends are ideal compost material.',
  ),
  WasteItem(
    id: 'coffee_grounds',
    name: 'Used coffee grounds',
    category: WasteCategory.organic,
    shape: ItemShape.grounds,
    zoneId: 'garden',
    explanation: 'Coffee grounds are a rich compost ingredient that adds nitrogen.',
  ),
  WasteItem(
    id: 'stale_bread',
    name: 'Stale bread',
    category: WasteCategory.organic,
    shape: ItemShape.bread,
    zoneId: 'garden',
    explanation:
        'Best first: do not waste it — stale bread is the base of lablabi or becomes breadcrumbs. Scraps that truly cannot be eaten can go to compost in small amounts.',
  ),
  WasteItem(
    id: 'eggshells',
    name: 'Eggshells',
    category: WasteCategory.organic,
    shape: ItemShape.eggshell,
    zoneId: 'garden',
    explanation: 'Crushed eggshells add minerals to compost.',
  ),

  // ---------- Residual ----------
  WasteItem(
    id: 'used_tissue',
    name: 'Used paper tissue',
    category: WasteCategory.residual,
    shape: ItemShape.tissue,
    explanation:
        'Used tissues are soiled and their fibres are too short to recycle, so they go to residual waste.',
    mistakeHint: 'It is paper, but used tissues are not accepted with paper recycling.',
  ),
  WasteItem(
    id: 'chip_packet',
    name: 'Crisp packet',
    category: WasteCategory.residual,
    shape: ItemShape.chipPacket,
    dependsOnLocalRules: true,
    explanation:
        'Shiny crisp packets are plastic and foil layers stuck together, which most schemes cannot recycle. Check if your area has a special collection.',
    mistakeHint: 'It is packaging, but these mixed layers usually cannot be recycled.',
  ),
  WasteItem(
    id: 'cigarette_butt',
    name: 'Cigarette butt',
    category: WasteCategory.residual,
    shape: ItemShape.cigarette,
    zoneId: 'square',
    explanation:
        'Filters contain plastic fibres and toxic residues. Fully put out, they go to residual waste — never on the pavement or in planters.',
  ),

  // ---------- Special drop-off ----------
  WasteItem(
    id: 'battery',
    name: 'AA battery',
    category: WasteCategory.special,
    shape: ItemShape.battery,
    dependsOnLocalRules: true,
    explanation:
        'Batteries contain metals that can leak, and can even start fires in bins and trucks. Keep them apart and use a battery collection point — check where one exists near you.',
    mistakeHint: 'It is small and metal, but batteries must never go with packaging.',
    safetyNote: 'Store used batteries in a dry box; tape the ends of larger ones.',
  ),
  WasteItem(
    id: 'old_charger',
    name: 'Old phone charger',
    category: WasteCategory.special,
    shape: ItemShape.cable,
    dependsOnLocalRules: true,
    explanation:
        'Cables and chargers are electronic waste. They contain valuable metals and should not go in household bins. Look for an e-waste collection or shop take-back.',
  ),
  WasteItem(
    id: 'medicine',
    name: 'Expired medicines',
    category: WasteCategory.special,
    shape: ItemShape.medicine,
    dependsOnLocalRules: true,
    explanation:
        'Never flush medicines or throw them loose in bins. Ask a pharmacy whether it accepts returns, or follow local guidance.',
    safetyNote: 'Keep medicines in their packaging and out of reach of children.',
  ),
  WasteItem(
    id: 'paint_tin',
    name: 'Leftover paint tin',
    category: WasteCategory.special,
    shape: ItemShape.paintTin,
    dependsOnLocalRules: true,
    explanation:
        'Paint can be harmful to water and soil — never pour it down drains. Keep the lid on and follow local guidance for hazardous household waste.',
    mistakeHint: 'It is a metal tin, but the paint inside makes it special waste.',
  ),
];

WasteItem? wasteItemById(String id) {
  for (final item in kWasteItems) {
    if (item.id == id) return item;
  }
  return null;
}
