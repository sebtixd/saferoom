import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

/// Service for local storage operations
abstract class LocalStorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> remove(String key);
  Future<void> clear();

  /// Keyed helpers for feature-scoped storage.
  Future<void> saveRoomDecor(String userId, List<Map<String, dynamic>> objects);
  Future<List<Map<String, dynamic>>> getRoomDecor(String userId);
}

/// Implementation of [LocalStorageService] using SharedPreferences
class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  @override
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  @override
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  static String _roomDecorKey(String userId) =>
      '${AppConstants.keyRoomState}_decor_${userId.isEmpty ? 'guest' : userId}';

  @override
  Future<void> saveRoomDecor(
    String userId,
    List<Map<String, dynamic>> objects,
  ) async {
    await saveJson(_roomDecorKey(userId), {'objects': objects});
  }

  @override
  Future<List<Map<String, dynamic>>> getRoomDecor(String userId) async {
    final json = await getJson(_roomDecorKey(userId));
    final raw = json?['objects'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  // Convenience methods for user data
  Future<void> saveUserId(String userId) async {
    await saveString(AppConstants.keyUserId, userId);
  }

  Future<String?> getUserId() async {
    return getString(AppConstants.keyUserId);
  }

  Future<void> setLoggedIn(bool value) async {
    await saveBool(AppConstants.keyIsLoggedIn, value);
  }

  Future<bool> isLoggedIn() async {
    final result = await getBool(AppConstants.keyIsLoggedIn);
    return result ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await saveBool(AppConstants.keyOnboardingComplete, value);
  }

  Future<bool> isOnboardingComplete() async {
    final result = await getBool(AppConstants.keyOnboardingComplete);
    return result ?? false;
  }
}
