import 'dart:convert';
import 'package:http/http.dart' as http;

class MealService {
  static const String baseUrl = "http://172.20.29.137:5001";

  static Future<List<dynamic>> searchMeals(String q) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/meals/search?q=${Uri.encodeComponent(q)}"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to search meals: ${response.body}");
    }
  }
}
