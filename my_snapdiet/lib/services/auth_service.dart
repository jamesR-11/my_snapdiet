import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: CHANGE THIS for iPhone (use your Mac IP)
  static const String baseUrl = "http://172.20.29.137:5001";

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    final data = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    throw Exception(data["message"] ?? "Signup failed");
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Save token
      final token = data["token"];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
      }
      return data;
    }

    throw Exception(data["message"] ?? "Login failed");
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"message": body};
    } catch (_) {
      return {"message": body};
    }
  }
}
