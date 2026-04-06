import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class MealCandidate {
  final String name;
  final double prob;
  final dynamic classId;
  final int? foodItemPosition;
  final String modelVersion;

  MealCandidate({
    required this.name,
    required this.prob,
    required this.classId,
    required this.foodItemPosition,
    required this.modelVersion,
  });
}

class LogMealService {
  static const String _token = '73297982d35fb28779a8188504a716f521b4a594';
  static const String _baseUrl = 'https://api.logmeal.com';

  static Map<String, String> get _jsonHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  static bool get hasToken => _token != 'YOUR_LOGMEAL_APIUSER_TOKEN';

  static Future<Map<String, dynamic>> recognizeMeal(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/v2/image/segmentation/complete'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected recognition response format');
    }

    throw Exception('Recognition failed: ${response.body}');
  }

  static Future<void> confirmDish({
    required String imageId,
    required MealCandidate candidate,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v2/image/confirm/dish/${candidate.modelVersion}'),
      headers: _jsonHeaders,
      body: jsonEncode({
        "imageId": int.tryParse(imageId) ?? imageId,
        "confirmedClass": [candidate.classId],
        "source": ["logmeal"],
        "food_item_position": [candidate.foodItemPosition],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Confirm dish failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getIngredients(String imageId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v2/nutrition/recipe/ingredients'),
      headers: _jsonHeaders,
      body: jsonEncode({'imageId': int.tryParse(imageId) ?? imageId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected ingredients response format');
    }

    throw Exception('Ingredients failed: ${response.body}');
  }

  static Future<Map<String, dynamic>> getNutrition(String imageId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v2/nutrition/recipe/nutritionalInfo'),
      headers: _jsonHeaders,
      body: jsonEncode({'imageId': int.tryParse(imageId) ?? imageId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected nutrition response format');
    }

    throw Exception('Nutrition failed: ${response.body}');
  }

  static String extractImageId(Map<String, dynamic> recognition) {
    final imageId = recognition["imageId"];
    if (imageId != null) return imageId.toString();

    final imageIdAlt = recognition["image_id"];
    if (imageIdAlt != null) return imageIdAlt.toString();

    throw Exception("No imageId found");
  }

  static List<MealCandidate> extractTopMealCandidates(
    Map<String, dynamic> recognition,
  ) {
    final List<MealCandidate> candidates = [];

    final segmentationResults = recognition["segmentation_results"];
    final modelVersions =
        recognition["model_versions"] as Map<String, dynamic>?;
    final modelVersion = (modelVersions?["foodrec"] ?? "v1.0").toString();

    if (segmentationResults is List) {
      for (final seg in segmentationResults) {
        if (seg is Map<String, dynamic>) {
          final foodItemPosition = seg["food_item_position"] as int?;
          final recognitionResults = seg["recognition_results"];

          if (recognitionResults is List) {
            for (final item in recognitionResults) {
              if (item is Map<String, dynamic>) {
                final name = (item["name"] ?? "").toString().trim();
                final classId = item["id"];
                final probRaw = item["prob"];
                final prob = probRaw is num
                    ? probRaw.toDouble()
                    : double.tryParse(probRaw.toString()) ?? 0.0;

                if (name.isNotEmpty && classId != null) {
                  candidates.add(
                    MealCandidate(
                      name: name,
                      prob: prob,
                      classId: classId,
                      foodItemPosition: foodItemPosition,
                      modelVersion: modelVersion,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    candidates.sort((a, b) => b.prob.compareTo(a.prob));

    final seen = <String>{};
    final unique = <MealCandidate>[];

    for (final c in candidates) {
      final key = c.name.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(c);
      }
    }

    return unique.take(2).toList();
  }

  static List<String> extractIngredients(
    Map<String, dynamic> ingredientsResponse,
  ) {
    final result = <String>[];

    void addText(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && !result.contains(text)) {
        result.add(text);
      }
    }

    final recipe = ingredientsResponse["recipe"];
    if (recipe is List) {
      for (final item in recipe) {
        if (item is Map<String, dynamic>) {
          addText(item["name"]);
        }
      }
    }

    final recipePerItem = ingredientsResponse["recipe_per_item"];
    if (recipePerItem is List) {
      for (final item in recipePerItem) {
        if (item is Map<String, dynamic>) {
          final nestedRecipe = item["recipe"];
          if (nestedRecipe is List) {
            for (final ing in nestedRecipe) {
              if (ing is Map<String, dynamic>) {
                addText(ing["name"]);
              }
            }
          }
        }
      }
    }

    return result;
  }

  static Map<String, dynamic> extractNutrition(
    Map<String, dynamic> nutritionResponse,
  ) {
    num pickNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      return num.tryParse(value.toString()) ?? 0;
    }

    final nutritionalInfo =
        (nutritionResponse["nutritional_info"] as Map<String, dynamic>?) ?? {};

    final totalNutrients =
        (nutritionalInfo["totalNutrients"] as Map<String, dynamic>?) ?? {};

    final proteinData =
        (totalNutrients["PROCNT"] as Map<String, dynamic>?) ?? {};
    final carbsData = (totalNutrients["CHOCDF"] as Map<String, dynamic>?) ?? {};
    final fatData = (totalNutrients["FAT"] as Map<String, dynamic>?) ?? {};

    return {
      "calories": pickNum(nutritionalInfo["calories"]),
      "protein": pickNum(proteinData["quantity"]),
      "carbs": pickNum(carbsData["quantity"]),
      "fat": pickNum(fatData["quantity"]),
    };
  }
}
