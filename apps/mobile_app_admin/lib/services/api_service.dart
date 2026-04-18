import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';

class ApiService {
  static String get baseUrl {
    const bool isProduction =
        false; // Toggle this to false for local development

    if (kIsWeb) {
      return isProduction
          ? 'https://app-production-0ff2.up.railway.app'
          : 'http://localhost:3000';
    }

    return isProduction
        ? 'https://app-production-0ff2.up.railway.app'
        : 'http://10.0.2.2:3000'; // Special IP for Android Emulator to reach host
  }

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 ||
        (response.statusCode == 404 && response.request?.url.path.endsWith('/users/me') == true) ||
        (response.statusCode == 404 && response.request?.url.path.endsWith('/admin/me') == true)) {
      await logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
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
