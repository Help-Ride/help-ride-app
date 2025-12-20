import 'package:google_sign_in/google_sign_in.dart';

class GoogleOAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  Future<GoogleOAuthResult?> signIn({bool forceAccountPicker = false}) async {
    if (forceAccountPicker) {
      await _googleSignIn.signOut();
    }

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;

    return GoogleOAuthResult(
      id: account.id,
      email: account.email,
      name: account.displayName ?? 'User',
      avatarUrl: account.photoUrl,
      idToken: auth.idToken,
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();
}

class GoogleOAuthResult {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? idToken;

  GoogleOAuthResult({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.idToken,
  });
}
