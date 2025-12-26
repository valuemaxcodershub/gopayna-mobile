import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user credentials storage and retrieval
class CredentialsService {
  static const String _usernameKey = 'saved_username';
  static const String _deviceIdKey = 'device_id';

  /// Save username to device storage
  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  /// Get saved username from device storage
  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Clear saved username
  static Future<void> clearSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }

  /// Generate and save a unique device ID
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      // Generate a unique device ID
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString()}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  /// Generate a random string for device ID
  static String _generateRandomString() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(
        DateTime.now().microsecond % chars.length
      ))
    );
  }
}