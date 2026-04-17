import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    const bool isProduction = true; // Toggle this to false for local development
    
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

  Future<http.Response> getRequest(String endpoint) async {
    final token = await getToken();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patchRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}
