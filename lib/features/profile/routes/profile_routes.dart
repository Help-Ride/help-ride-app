import 'package:get/get.dart';
import '../views/stripe_connect_return_view.dart';
import '../views/terms_privacy_view.dart';

class ProfileRoutes {
  static const termsPrivacy = '/profile/terms-privacy';
  static const stripeConnectReturn = '/stripe/return';

  static final pages = [
    GetPage(name: termsPrivacy, page: () => const TermsPrivacyView()),
    GetPage(
      name: stripeConnectReturn,
      page: () => const StripeConnectReturnView(),
    ),
  ];
}
