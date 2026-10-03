import '../models/app_user.dart';

/// Authentication boundary. In DEMO MODE it validates against seeded test
/// accounts. A Firebase Auth / campus SSO (OAuth2/OIDC) implementation should
/// implement the same interface — see README "Firebase Setup".
abstract class AuthService {
  AppUser? signIn(String email, String password);
}

class DemoAuthService implements AuthService {
  DemoAuthService(this._users);
  final Iterable<AppUser> Function() _users;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validate(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) return 'Enter email and password.';
    if (!_emailRe.hasMatch(email.trim())) return 'Enter a valid email address.';
    return null;
  }

  @override
  AppUser? signIn(String email, String password) {
    final e = email.trim().toLowerCase();
    for (final u in _users()) {
      if (u.email.toLowerCase() == e && u.password == password) return u;
    }
    return null;
  }
}
