import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  // ✅ iPhone needs Mac IP (NOT localhost)
  static const String baseUrl = "http://172.20.29.137:5001"; // <-- change this

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse("$baseUrl/api/profile"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    final data = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data["message"] ?? "Failed to load profile");
  }

  /// Sends full profile object (recommended)
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profile,
  ) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse("$baseUrl/api/profile"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(profile),
    );

    final data = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data["message"] ?? "Failed to update profile");
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
