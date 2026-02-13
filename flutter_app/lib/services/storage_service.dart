import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'sfm_token';
  static const _userKey = 'sfm_user';
  static const _societyKey = 'sfm_society';

  // ── Token ─────────────────────────────────────────────
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── User ──────────────────────────────────────────────
  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Society ───────────────────────────────────────────
  Future<void> saveSociety(Map<String, dynamic> society) =>
      _storage.write(key: _societyKey, value: jsonEncode(society));

  Future<Map<String, dynamic>?> getSociety() async {
    final raw = await _storage.read(key: _societyKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Clear ─────────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
