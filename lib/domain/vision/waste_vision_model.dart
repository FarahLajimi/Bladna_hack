import '../../data/models/waste_category.dart';

/// What a REAL waste-recognition model returns for one photo.
class VisionPrediction {
  const VisionPrediction({
    required this.category,
    required this.methodId,
    this.confidence,
    this.uncertaintyNote = '',
  });

  final WasteCategory category;

  /// Model or method identification, e.g. "litter-lens-yolo-v1 (TFLite)".
  final String methodId;

  /// 0..1 — only when the model actually produces one.
  final double? confidence;

  /// Plain explanation of what could make this prediction wrong.
  final String uncertaintyNote;
}

/// The single place where computer vision plugs into BLADNA.
///
/// This build ships [NoModelYet]: the player records MANUAL observations.
/// A later version can implement this interface with an on-device model —
/// e.g. an object detector fine-tuned on an open litter dataset such as TACO
/// plus the team's own field-evidence records, exported to TensorFlow Lite.
/// The Field Evidence screen already shows a "suggestion" slot and asks the
/// player to confirm or correct it (human-in-the-loop), and records store the
/// model name next to the manual label so the two are never confused.
abstract class WasteVisionModel {
  const WasteVisionModel();

  String get name;

  /// False when no model is installed: the UI then shows "manual observation".
  bool get available;

  Future<VisionPrediction?> classify(String imagePath);
}

/// Honest placeholder: no model, no predictions, no invented confidence.
class NoModelYet extends WasteVisionModel {
  const NoModelYet();

  @override
  String get name => 'No model installed';

  @override
  bool get available => false;

  @override
  Future<VisionPrediction?> classify(String imagePath) async => null;
}

/// The model used by the app. Swap this for a real implementation later.
const WasteVisionModel kWasteVisionModel = NoModelYet();
