import 'package:get/get.dart';
import '../views/terms_privacy_view.dart';

class ProfileRoutes {
  static const termsPrivacy = '/profile/terms-privacy';

  static final pages = [
    GetPage(
      name: termsPrivacy,
      page: () => const TermsPrivacyView(),
    ),
  ];
}

