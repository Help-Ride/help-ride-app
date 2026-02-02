import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'shared/services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Explicit path — no guessing
  await dotenv.load(fileName: ".env");

  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim();
  final stripeMerchantId = dotenv.env['STRIPE_MERCHANT_IDENTIFIER']?.trim();
  if (stripeKey != null && stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    if (stripeMerchantId != null && stripeMerchantId.isNotEmpty) {
      Stripe.merchantIdentifier = stripeMerchantId;
    }
    await Stripe.instance.applySettings();
  } else if (kDebugMode) {
    debugPrint('Missing STRIPE_PUBLISHABLE_KEY in .env');
  }

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await GetStorage.init();
  await PushNotificationService.instance.init();

  runApp(const HelpRideApp());
}
