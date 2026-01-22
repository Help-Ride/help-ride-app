import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'shared/services/api_client.dart';
import 'shared/controllers/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await GetStorage.init();

  // Register ApiClient globally
  await Get.putAsync<ApiClient>(
        () async => await ApiClient.create(),
    permanent: true,
  );

  // Register SessionController globally
  Get.put(SessionController(), permanent: true);

  runApp(const HelpRideApp());
}
