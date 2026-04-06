import 'dart:convert';
import 'package:http/http.dart' as http;

class AINutritionService {
  // Put your real API Ninjas key here
  static const String apiKey = "CiyEKUcjjbWo9ScJQfwygmMPKwSCWsBj0zqMMvFt";

  static Future<Map<String, dynamic>?> getNutritionFromDishName(
    String dishName,
  ) async {
    final cleanName = dishName.trim();
    if (cleanName.isEmpty) return null;

    final url =
        "https://api.api-ninjas.com/v1/nutrition?query=${Uri.encodeComponent(cleanName)}";

    final res = await http.get(Uri.parse(url), headers: {"X-Api-Key": apiKey});

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch AI nutrition");
    }

    final data = jsonDecode(res.body);

    if (data == null || data is! List || data.isEmpty) {
      return null;
    }

    return _combineNutritionItems(data);
  }

  static Map<String, dynamic> _combineNutritionItems(List<dynamic> items) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);

      calories += _toNum(item["calories"]);
      protein += _toNum(item["protein_g"]);
      carbs += _toNum(item["carbohydrates_total_g"]);
      fat += _toNum(item["fat_total_g"]);
    }

    return {
      "calories": calories,
      "protein": protein,
      "carbs": carbs,
      "fat": fat,
    };
  }

  static double _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    final parsed = double.tryParse(value.toString().trim());
    return parsed ?? 0;
  }
}
