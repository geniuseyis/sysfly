import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/motion.dart';
import '../../core/errors/app_exception.dart';
import '../../core/storage/key_value_store.dart';
import '../../data/mock/demo_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';

@immutable
class AuthState {
  const AuthState({this.user, this.loading = false, this.error});

  final UserProfile? user;
  final bool loading;
  final String? error;

  bool get isSignedIn => user != null;

  AuthState copyWith({UserProfile? user, bool? loading, String? error, bool clearError = false}) => AuthState(
        user: user ?? this.user,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  /// Email saved by "Remember me". The password is never stored.
  String? get rememberedEmail => _store.getString(StorageKeys.rememberedEmail);

  /// Runs [action] behind the loading state. The loader is kept up for at
  /// least [SysflyMotion.loaderMinimum] so it never flashes.
  Future<bool> _run(Future<UserProfile> Function() action) async {
    if (state.loading) return false;
    state = state.copyWith(loading: true, clearError: true);
    final started = DateTime.now();
    try {
      final user = await action();
      final elapsed = DateTime.now().difference(started);
      if (elapsed < SysflyMotion.loaderMinimum) {
        await Future<void>.delayed(SysflyMotion.loaderMinimum - elapsed);
      }
      state = AuthState(user: user);
      return true;
    } catch (error) {
      state = AuthState(error: describeError(error));
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password, required bool remember}) async {
    final ok = await _run(() => ref.read(authRepositoryProvider).signIn(email: email, password: password));
    if (ok) {
      if (remember) {
        await _store.setString(StorageKeys.rememberedEmail, email.trim());
      } else {
        await _store.remove(StorageKeys.rememberedEmail);
      }
    }
    return ok;
  }

  Future<bool> signUp({required String name, required String email, required String password}) =>
      _run(() => ref.read(authRepositoryProvider).signUp(name: name, email: email, password: password));

  /// Throws [NotConfiguredException] in the demo build.
  Future<void> signInWith(SocialProvider provider) async {
    final user = await ref.read(authRepositoryProvider).signInWith(provider);
    state = AuthState(user: user);
  }

  Future<void> sendPasswordReset(String email) => ref.read(authRepositoryProvider).sendPasswordReset(email);

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  void updateProfile(UserProfile profile) => state = AuthState(user: profile);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in traveller. Falls back to the demo profile so screens can be
/// built in isolation.
final currentUserProvider = Provider<UserProfile>((ref) => ref.watch(authControllerProvider).user ?? DemoCatalog.user);
