import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';

class ApiService {
  static String get baseUrl {
    // Automatically switches based on build mode:
    // - Development (flutter run): uses localhost/10.0.2.2
    // - Production (flutter build): uses the live URL
    const bool isProduction = kReleaseMode;

    if (kIsWeb) {
      return isProduction
          ? 'https://equinoxexchange.cc'
          : 'http://localhost:3200';
    }

    // For USB Debugging (Physical Device) or Emulator:
    // 1. Run this command in your terminal: adb reverse tcp:3200 tcp:3200
    // & $env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe reverse tcp:3200 tcp:3200
    // 2. The app will then connect to your computer's localhost:3200
    return isProduction
        ? 'https://equinoxexchange.cc'
        : 'http://127.0.0.1:3200';
  }

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'admin_token', value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
      await _storage.deleteAll();
      await _storage.write(key: 'admin_token', value: token);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'admin_token');
    } catch (e) {
      debugPrint('Error reading token: $e');
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'admin_token');
    } catch (e) {
      await _storage.deleteAll();
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 ||
        (response.statusCode == 404 &&
            response.request?.url.path.endsWith('/api/users/me') == true) ||
        (response.statusCode == 404 &&
            response.request?.url.path.endsWith('/api/admin/me') == true)) {
      await logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<http.Response> getRequest(String endpoint) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> patchRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> deleteRequest(String endpoint) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    await _handleResponse(response);
    return response;
  }
}
