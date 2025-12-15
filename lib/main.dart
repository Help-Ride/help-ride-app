import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Explicit path — no guessing
  await dotenv.load(fileName: ".env");

  await GetStorage.init();

  runApp(const HelpRideApp());
}
