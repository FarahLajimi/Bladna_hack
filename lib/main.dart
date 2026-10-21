import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await ProgressRepository.open();
  runApp(BladnaApp(repository: repository));
}
