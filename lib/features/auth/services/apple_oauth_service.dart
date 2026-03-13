import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleOAuthService {
  Future<AppleOAuthResult?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userIdentifier = credential.userIdentifier?.trim() ?? '';
      if (userIdentifier.isEmpty) {
        throw Exception('Apple sign-in did not return a user identifier.');
      }

      final givenName = credential.givenName?.trim() ?? '';
      final familyName = credential.familyName?.trim() ?? '';
      final fullName = [
        givenName,
        familyName,
      ].where((part) => part.isNotEmpty).join(' ').trim();

      return AppleOAuthResult(
        userIdentifier: userIdentifier,
        email: credential.email?.trim(),
        fullName: fullName.isEmpty ? null : fullName,
        identityToken: credential.identityToken?.trim(),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw Exception(error.message);
    } on SignInWithAppleException catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', '').trim());
    }
  }
}

class AppleOAuthResult {
  const AppleOAuthResult({
    required this.userIdentifier,
    this.email,
    this.fullName,
    this.identityToken,
  });

  final String userIdentifier;
  final String? email;
  final String? fullName;
  final String? identityToken;
}
