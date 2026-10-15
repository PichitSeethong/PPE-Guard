import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

class AuthStore {
  AuthStore._();

  static final instance = AuthStore._();
  static const _tokenKey = 'ppe_guard_token';

  final ValueNotifier<AppUser?> user = ValueNotifier<AppUser?>(null);

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) return;
    ApiClient.instance.setAccessToken(token);
    try {
      final data = await ApiClient.instance.get('/api/v1/auth/me');
      user.value = AppUser.fromJson((data as Map).cast<String, dynamic>());
    } catch (_) {
      await signOut();
    }
  }

  Future<void> signIn({required String username, required String password}) async {
    final data = await ApiClient.instance.post('/api/v1/auth/login', {'username': username.trim(), 'password': password}, authenticated: false);
    await _applyAuthResponse((data as Map).cast<String, dynamic>());
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final data = await ApiClient.instance.post(
      '/api/v1/auth/change-password',
      {'current_password': currentPassword, 'new_password': newPassword},
    );
    await _applyAuthResponse((data as Map).cast<String, dynamic>());
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> map) async {
    final token = map['access_token']?.toString();
    if (token == null || token.isEmpty) throw const ApiException('Server ไม่ส่ง access token กลับมา');
    ApiClient.instance.setAccessToken(token);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    final rawUser = map['user'];
    if (rawUser is Map) {
      user.value = AppUser.fromJson(rawUser.cast<String, dynamic>());
    } else {
      final profile = await ApiClient.instance.get('/api/v1/auth/me');
      user.value = AppUser.fromJson((profile as Map).cast<String, dynamic>());
    }
  }

  Future<void> signOut() async {
    ApiClient.instance.setAccessToken(null);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    user.value = null;
  }
}
