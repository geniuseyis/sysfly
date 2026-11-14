import '../../core/errors/app_exception.dart';
import '../../shared/models/models.dart';
import '../mock/demo_catalog.dart';

enum SocialProvider {
  google('Google'),
  apple('Apple');

  const SocialProvider(this.label);
  final String label;
}

/// Sign-in backend. Replace [DemoAuthRepository] with a real implementation
/// to connect an identity service.
abstract interface class AuthRepository {
  Future<UserProfile> signIn({required String email, required String password});
  Future<UserProfile> signUp({required String name, required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<UserProfile> signInWith(SocialProvider provider);
  Future<void> signOut();
}

/// In-memory accounts for the demo.
///
/// The seeded account (see [DemoCatalog.user]) has a fixed password and
/// rejects any other. Any other well-formed email is accepted with a password
/// of six or more characters and opens the same demo traveller, so the app
/// can be explored without registering. Google and Apple sign-in need
/// platform configuration and report that instead of pretending to work.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({this.latency = const Duration(milliseconds: 1600)});

  final Duration latency;
  final Map<String, ({String password, UserProfile profile})> _accounts = {
    DemoCatalog.user.email: (password: DemoCatalog.demoPassword, profile: DemoCatalog.user),
  };

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    await Future<void>.delayed(latency);
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account != null) {
      if (account.password != password) throw const AuthException('Incorrect password for this account');
      return account.profile;
    }
    return DemoCatalog.user;
  }

  @override
  Future<UserProfile> signUp({required String name, required String email, required String password}) async {
    await Future<void>.delayed(latency);
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw const AuthException('An account with this email already exists');
    final profile = DemoCatalog.user.copyWith(
      displayName: name.trim(),
      email: key,
      traveller: DemoCatalog.traveller.copyWith(fullName: name.trim()),
    );
    _accounts[key] = (password: password, profile: profile);
    return profile;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<UserProfile> signInWith(SocialProvider provider) async {
    throw NotConfiguredException('${provider.label} sign-in is not set up in this demo build');
  }

  @override
  Future<void> signOut() async {}
}
