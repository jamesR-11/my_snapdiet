import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/meal_service.dart';
import '../services/profile_service.dart';
import '../pages/meal_detail_page.dart';

class UploadTab extends StatefulWidget {
  const UploadTab({super.key});

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _loading = false;
  String _recognizedText = '';
  List<String> _detectedMenuItems = [];
  List<Map<String, dynamic>> _matchedMeals = [];

  final List<String> _foodWords = [
    'chicken',
    'beef',
    'steak',
    'salmon',
    'tuna',
    'fish',
    'shrimp',
    'prawn',
    'crab',
    'oyster',
    'octopus',
    'burger',
    'sandwich',
    'sub',
    'club',
    'cheese',
    'pasta',
    'spaghetti',
    'fettuccine',
    'tortellini',
    'ravioli',
    'alfredo',
    'pizza',
    'salad',
    'soup',
    'fries',
    'beans',
    'zucchini',
    'eggplant',
    'calamari',
    'dumplings',
    'gyoza',
    'tofu',
    'tempura',
    'yakitori',
    'edamame',
    'rolls',
    'juice',
    'tea',
    'coffee',
    'milkshake',
    'chocolate',
    'omelette',
    'cake',
    'bites',
    'special',
    'avocado',
    'hamachi',
    'water',
    'cocktail',
    'milk',
    'samosa',
    'nachos',
    'puri',
    'curry',
    'bowl',
    'flatbread',
    'wrap',
    'paneer',
    'khichuri',
    'lasagna',
    'tiramisu',
    'brulee',
  ];

  final List<String> _blockedWords = [
    'restaurant',
    'menu',
    'men',
    'thynk',
    'unlimited',
    'for the love of food',
    'appetizer',
    'appetizers',
    'main dish',
    'main dishes',
    'drink',
    'drinks',
    'dessert',
    'desserts',
    'starter',
    'starters',
    'beverage',
    'beverages',
    'breakfast',
    'lunch',
    'dinner',
    'salads',
    'sandwiches',
    '.jpg',
    '.jpeg',
    '.png',
    'www.',
    '.com',
  ];

  Future<void> _takeMenuPhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedText = '';
        _detectedMenuItems = [];
        _matchedMeals = [];
      });
    }
  }

  Future<void> _uploadMenuImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedText = '';
        _detectedMenuItems = [];
        _matchedMeals = [];
      });
    }
  }

  Future<void> _extractText() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
      _recognizedText = '';
      _detectedMenuItems = [];
      _matchedMeals = [];
    });

    final inputImage = InputImage.fromFile(_image!);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      final rawLines = <String>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) {
            rawLines.add(text);
          }
        }
      }

      final items = _extractMenuItemsAI(rawLines);

      setState(() {
        _recognizedText = recognizedText.text;
        _detectedMenuItems = items;
      });

      await _matchMealsWithBackend(items);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to extract text: $e')));
    } finally {
      await textRecognizer.close();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _matchMealsWithBackend(List<String> items) async {
    Map<String, dynamic> profile = {};

    try {
      final profileData = await ProfileService.getProfile();
      profile = (profileData["profile"] ?? {}) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Profile load failed: $e");
      profile = {};
    }

    final List<Map<String, dynamic>> results = [];
    final Set<String> seenMealIds = {};

    for (final item in items) {
      try {
        final cleanItem = item
            .replaceAll(RegExp(r'[^\w\s&-]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (cleanItem.isEmpty) continue;

        debugPrint("Searching meal: [$cleanItem]");

        List<dynamic> meals = await MealService.searchMeals(cleanItem);

        if (meals.isEmpty && cleanItem.contains('&')) {
          final fallback = cleanItem.replaceAll('&', 'and');
          debugPrint("Fallback search: [$fallback]");
          meals = await MealService.searchMeals(fallback);
        }

        if (meals.isEmpty && cleanItem.split(' ').length > 2) {
          final fallback = cleanItem.split(' ').take(2).join(' ');
          debugPrint("Fallback search: [$fallback]");
          meals = await MealService.searchMeals(fallback);
        }

        debugPrint("Result count for [$cleanItem]: ${meals.length}");

        if (meals.isNotEmpty) {
          final meal = Map<String, dynamic>.from(meals.first);

          final id = (meal["_id"] ?? meal["name"] ?? cleanItem).toString();
          if (seenMealIds.contains(id)) continue;
          seenMealIds.add(id);

          final status = _compareMealWithProfile(meal, profile);
          results.add({...meal, "status": status});
        }
      } catch (e) {
        debugPrint("Search failed for [$item]: $e");
      }
    }

    debugPrint("Final matched meals count: ${results.length}");

    if (mounted) {
      setState(() {
        _matchedMeals = results;
      });
    }
  }

  String _compareMealWithProfile(
    Map<String, dynamic> meal,
    Map<String, dynamic> profile,
  ) {
    final ingredients = (meal["ingredients"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    final userAllergies = (profile["allergies"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    final avoidFoods = (profile["avoidFoods"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    bool containsMatch(String keyword) {
      for (final ingredient in ingredients) {
        if (ingredient.contains(keyword) || keyword.contains(ingredient)) {
          return true;
        }
      }
      return false;
    }

    for (final allergy in userAllergies) {
      if (allergy.isNotEmpty && containsMatch(allergy)) {
        return "red";
      }
    }

    for (final food in avoidFoods) {
      if (food.isNotEmpty && containsMatch(food)) {
        return "red";
      }
    }

    final nutrition = (meal["nutrition"] ?? {}) as Map<String, dynamic>;

    final calories = _toNum(nutrition["calories"]);
    final protein = _toNum(nutrition["protein"]);
    final carbs = _toNum(nutrition["carbs"]);
    final fat = _toNum(nutrition["fat"]);

    final caloriesTarget = _toNum(profile["caloriesTarget"]);
    final proteinTarget = _toNum(profile["proteinTarget"]);
    final carbsTarget = _toNum(profile["carbsTarget"]);
    final fatTarget = _toNum(profile["fatTarget"]);

    if ((caloriesTarget > 0 && calories > caloriesTarget) ||
        (proteinTarget > 0 && protein > proteinTarget) ||
        (carbsTarget > 0 && carbs > carbsTarget) ||
        (fatTarget > 0 && fat > fatTarget)) {
      return "orange";
    }

    return "green";
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "red":
        return Icons.close;
      case "orange":
        return Icons.circle;
      default:
        return Icons.check;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "red":
        return Colors.red;
      case "orange":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  List<String> _extractMenuItemsAI(List<String> rawLines) {
    final cleanedLines = rawLines
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final candidates = <String>[];

    for (int i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i];

      if (_looksLikePriceOnly(line)) continue;
      if (_looksLikeJunk(line)) continue;
      if (_isBlockedHeading(line)) continue;

      final sameLineMatch = RegExp(
        r'^(.*?)\s+\$?\s*\d+([.,]\d{1,2})\s*$',
      ).firstMatch(line);

      if (sameLineMatch != null) {
        final mealName = _normalizeMealName(sameLineMatch.group(1) ?? '');
        if (_isGoodMealCandidate(mealName)) {
          candidates.add(mealName);
        }
        continue;
      }

      if (i + 1 < cleanedLines.length &&
          _looksLikePriceOnly(cleanedLines[i + 1])) {
        final mealName = _normalizeMealName(line);
        if (_isGoodMealCandidate(mealName)) {
          candidates.add(mealName);
        }
        continue;
      }

      if (i + 1 < cleanedLines.length &&
          !_looksLikePriceOnly(cleanedLines[i + 1]) &&
          !_isBlockedHeading(cleanedLines[i + 1])) {
        final merged = _normalizeMealName('$line ${cleanedLines[i + 1]}');
        if (_isGoodMealCandidate(merged)) {
          candidates.add(merged);
        }
      }

      final single = _normalizeMealName(line);
      if (_isGoodMealCandidate(single)) {
        candidates.add(single);
      }
    }

    final result = <String>[];
    final seen = <String>{};

    for (final item in candidates) {
      final key = item.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(item);
      }
    }

    return result;
  }

  bool _isBlockedHeading(String text) {
    final lower = text.toLowerCase().trim();

    for (final word in _blockedWords) {
      if (lower == word || lower.contains(word)) {
        return true;
      }
    }
    return false;
  }

  bool _isGoodMealCandidate(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.length < 3) return false;
    if (_looksLikePriceOnly(t)) return false;
    if (_looksLikeJunk(t)) return false;
    if (_isBlockedHeading(t)) return false;

    final words = t.split(RegExp(r'\s+'));
    if (words.length > 5) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(t)) return false;

    return true;
  }

  String _normalizeMealName(String input) {
    String text = input.trim();

    text = text.replaceAll(RegExp(r'\s+\$?\s*\d+([.,]\d{1,2})\s*$'), '');
    text = text.replaceAll(RegExp(r'^[^A-Za-z]+'), '');
    text = text.replaceAll(RegExp(r'[^A-Za-z]+$'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  bool _looksLikePriceOnly(String text) {
    return RegExp(r'^\$?\s*\d+([.,]\d{1,2})?\s*$').hasMatch(text.trim());
  }

  bool _looksLikeJunk(String text) {
    final t = text.trim();

    if (t.isEmpty) return true;
    if (t.length <= 2) return true;
    if (!RegExp(r'[A-Za-z]').hasMatch(t)) return true;
    if (RegExp(r'^[A-Za-z]?\d+$').hasMatch(t)) return true;
    if (t.contains('.jpg') || t.contains('.jpeg') || t.contains('.png')) {
      return true;
    }
    if (t.contains('/')) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final meals = _matchedMeals;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Menu Scanner",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload or take a menu photo, then extract and compare meals.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takeMenuPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Picture"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadMenuImage,
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload Image"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _image == null
                  ? const Center(
                      child: Text(
                        "No menu image selected",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_image == null || _loading) ? null : _extractText,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Analyze Menu"),
              ),
            ),

            if (meals.isNotEmpty) ...[
              const Text(
                "Analyze Menu List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...List.generate(meals.length, (index) {
                final meal = meals[index];
                final status = (meal["status"] ?? "green").toString();

                return Card(
                  child: ListTile(
                    title: Text(
                      "${index + 1}. ${meal["name"] ?? ""}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      _statusIcon(status),
                      color: _statusColor(status),
                      size: 26,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealDetailPage(meal: meal),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],

            if (!_loading &&
                _image != null &&
                meals.isEmpty &&
                _recognizedText.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "No matched meals found",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Try a clearer image or add these meals into your backend dataset.",
              ),
            ],
          ],
        ),
      ),
    );
  }
}
