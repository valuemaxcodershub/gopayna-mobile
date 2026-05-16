import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores JWT in platform secure storage (Keychain / Keystore). Migrates legacy SharedPreferences `jwt` once.
class AuthTokenStorage {
  AuthTokenStorage._();
  static const _jwtKey = 'jwt';
  static const _expKey = 'jwt_exp_ms';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> _migrateLegacyJwtOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_jwtKey);
    if (legacy == null || legacy.isEmpty) return;
    await _secure.write(key: _jwtKey, value: legacy);
    await prefs.remove(_jwtKey);
    await _persistExpiryFromToken(legacy);
  }

  static Future<void> _persistExpiryFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map && payload['exp'] != null) {
        final exp = payload['exp'];
        final sec = exp is num ? exp.toDouble() : double.tryParse('$exp');
        if (sec != null) {
          final ms = (sec * 1000).round();
          await _secure.write(key: _expKey, value: '$ms');
        }
      }
    } catch (_) {
      // Ignore malformed JWT payload on client
    }
  }

  /// Returns null if missing or past expiry (with 30s skew).
  static Future<String?> readJwt() async {
    await _migrateLegacyJwtOnce();
    final token = await _secure.read(key: _jwtKey);
    if (token == null || token.isEmpty) return null;

    final expStr = await _secure.read(key: _expKey);
    if (expStr != null) {
      final expMs = int.tryParse(expStr);
      if (expMs != null &&
          DateTime.now().millisecondsSinceEpoch >= expMs - 30000) {
        await clearJwt();
        if (kDebugMode) {
          debugPrint('[AuthTokenStorage] JWT expired locally; cleared.');
        }
        return null;
      }
    }

    return token;
  }

  static Future<void> writeJwt(String token) async {
    await _secure.write(key: _jwtKey, value: token);
    await _persistExpiryFromToken(token);
  }

  /// Clears secure JWT and legacy SharedPreferences key.
  static Future<void> clearJwt() async {
    await _secure.delete(key: _jwtKey);
    await _secure.delete(key: _expKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
  }
}
