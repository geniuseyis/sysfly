import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small persistent store for non-sensitive preferences. Card numbers,
/// passwords and passport numbers are never written here.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  List<String> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  bool getBool(String key, {bool fallback = false});
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _values = {};

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  List<String> getStringList(String key) => List<String>.from(_values[key] as List? ?? const []);

  @override
  Future<void> setStringList(String key, List<String> value) async => _values[key] = List<String>.from(value);

  @override
  bool getBool(String key, {bool fallback = false}) => _values[key] as bool? ?? fallback;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const [];

  @override
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  @override
  bool getBool(String key, {bool fallback = false}) => _prefs.getBool(key) ?? fallback;

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

abstract final class StorageKeys {
  static const rememberedEmail = 'auth.remembered_email';
  static const readNotifications = 'notifications.read_ids';
  static const hapticsEnabled = 'settings.haptics';
  static const seatPreference = 'settings.seat_preference';
  static const language = 'settings.language';
}

/// Overridden in `main()` with a [PrefsKeyValueStore]; tests keep the
/// in-memory default.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) => MemoryKeyValueStore());
