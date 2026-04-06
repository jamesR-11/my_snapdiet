import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MealLogService {
  static const String baseUrl = "http://172.20.29.137:5001";

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> createMealLog({
    required String mealName,
    required String cuisine,
    required String category,
    required Map<String, dynamic> nutrition,
    String source = "menu",
    String? eatenAt,
  }) async {
    final token = await _token();

    final res = await http.post(
      Uri.parse("$baseUrl/api/meal-logs"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "mealName": mealName,
        "cuisine": cuisine,
        "category": category,
        "nutrition": {
          "calories": nutrition["calories"] ?? 0,
          "protein": nutrition["protein"] ?? 0,
          "carbs": nutrition["carbs"] ?? 0,
          "fat": nutrition["fat"] ?? 0,
        },
        "source": source,
        if (eatenAt != null) "eatenAt": eatenAt,
      }),
    );

    final data = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data["message"] ?? "Failed to save meal log");
  }

  static Future<List<dynamic>> getMealLogs() async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/api/meal-logs"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      return [];
    }

    final data = _safeJson(res.body);
    throw Exception(data["message"] ?? "Failed to load meal logs");
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
