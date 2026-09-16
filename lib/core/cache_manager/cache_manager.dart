import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const _accessTokenKey = 'token';
  static const _fcmToken = 'fcmToken';
  static const _userIdKey = 'userId';
  static const _isGuestModeKey = 'isGuestMode';
  static SharedPreferences? _sharedPreferences;

  // Singleton instance
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  // Initialize SharedPreferences
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  // Getter for sharedPreferences with null check
  static SharedPreferences get sharedPreferences {
    if (_sharedPreferences == null) {
      throw Exception(
          'SharedPreferences not initialized. Call CacheManager.init() first.');
    }
    return _sharedPreferences!;
  }

  Future<bool> saveData({required String key, required dynamic value}) async {
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    } else if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else {
      return await sharedPreferences.setDouble(key, value);
    }
  }

  dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  static Future<bool> saveAddress(
      {required String key, required dynamic value}) async {
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    } else if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else {
      return await sharedPreferences.setDouble(key, value);
    }
  }

  static dynamic getAdderess({required String key}) {
    return sharedPreferences.get(key);
  }

  static Future<bool> removeAddress({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  static Future<String?> fetchAndSaveFcmToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await saveFcmTokenToken(fcmToken);
        log('FCM Token fetched and saved: $fcmToken');
        return fcmToken;
      } else {
        log('Failed to fetch FCM Token: Token is null');
        return null;
      }
    } catch (e) {
      log('Error fetching FCM Token: $e');
      return null;
    }
  }

  static Future<void> saveAccessToken(String token) async {
    await sharedPreferences.setString(_accessTokenKey, token);
    log('Token saved: $token');
  }

  static Future<void> delAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    log('token deleted');
  }

  static Future<void> saveFcmTokenToken(String fcmToken) async {
    await sharedPreferences.setString(_fcmToken, fcmToken);
    log('FCM Token saved: $fcmToken');
  }

  static Future<String?> getAccessToken() async {
    String? token = sharedPreferences.getString(_accessTokenKey);
    log('Token retrieved: $token');
    return token;
  }

  static Future<String?> getFcmToken() async {
    String? fcmToken = sharedPreferences.getString(_fcmToken);
    log('FCM Token retrieved: $fcmToken');
    return fcmToken;
  }

  static Future<bool> clear() async {
    try {
      await sharedPreferences.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveUserId(int userId) async {
    await sharedPreferences.setInt(_userIdKey, userId);
    log('User ID saved: $userId');
  }

  static Future<int?> getUserId() async {
    final userId = sharedPreferences.getInt(_userIdKey);
    log('User ID retrieved: $userId');
    return userId;
  }

  /// Set guest mode flag
  static Future<void> setGuestMode(bool isGuest) async {
    await sharedPreferences.setBool(_isGuestModeKey, isGuest);
    log('Guest mode set to: $isGuest');
  }

  /// Returns whether guest mode is enabled. Defaults to false when not set.
  static Future<bool> isGuestMode() async {
    final val = sharedPreferences.getBool(_isGuestModeKey) ?? false;
    log('Guest mode retrieved: $val');
    return val;
  }

  /// Remove guest mode flag
  static Future<void> clearGuestMode() async {
    await sharedPreferences.remove(_isGuestModeKey);
    log('Guest mode cleared');
  }

  /// Toggle guest mode and return the new value
  static Future<bool> toggleGuestMode() async {
    final current = sharedPreferences.getBool(_isGuestModeKey) ?? false;
    final next = !current;
    await sharedPreferences.setBool(_isGuestModeKey, next);
    log('Guest mode toggled: $next');
    return next;
  }
}
