import 'package:flutter/material.dart';
import '../services/meal_log_service.dart';
import '../services/ai_nutrition_service.dart';
import '../services/profile_service.dart';

class MealDetailPage extends StatefulWidget {
  final Map<String, dynamic> meal;

  const MealDetailPage({super.key, required this.meal});

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  bool _saving = false;

  // false = database, true = AI
  bool _useAiNutrition = false;
  bool _aiLoading = false;
  String? _aiError;

  Map<String, dynamic>? _aiNutrition;
  Map<String, dynamic> _profile = {};
  String _status = "green";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileService.getProfile();
      if (!mounted) return;

      setState(() {
        _profile = (data["profile"] ?? {}) as Map<String, dynamic>;
      });

      _recalculateStatus();
    } catch (e) {
      debugPrint("Profile load failed: $e");
    }
  }

  Future<void> _loadAiNutrition() async {
    if (_aiNutrition != null) return;

    setState(() {
      _aiLoading = true;
      _aiError = null;
    });

    try {
      final mealName = (widget.meal["name"] ?? "").toString();
      final nutrition = await AINutritionService.getNutritionFromDishName(
        mealName,
      );

      if (!mounted) return;

      setState(() {
        _aiNutrition = nutrition;
      });

      _recalculateStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _aiError = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _aiLoading = false;
        });
      }
    }
  }

  Future<void> _onNutritionModeChanged(bool useAi) async {
    setState(() {
      _useAiNutrition = useAi;
    });

    if (useAi && _aiNutrition == null && !_aiLoading) {
      await _loadAiNutrition();
    }

    _recalculateStatus();
  }

  Map<String, dynamic> _currentNutrition() {
    final dbNutrition =
        (widget.meal["nutrition"] ?? {}) as Map<String, dynamic>;

    if (_useAiNutrition && _aiNutrition != null) {
      return _aiNutrition!;
    }

    return dbNutrition;
  }

  String? _ingredientRisk() {
    final ingredients = (widget.meal["ingredients"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    final allergies = (_profile["allergies"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    final avoidFoods = (_profile["avoidFoods"] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    bool containsMatch(String keyword) {
      return ingredients.any(
        (ingredient) =>
            ingredient.contains(keyword) || keyword.contains(ingredient),
      );
    }

    for (final allergy in allergies) {
      if (allergy.isNotEmpty && containsMatch(allergy)) {
        return "red";
      }
    }

    for (final food in avoidFoods) {
      if (food.isNotEmpty && containsMatch(food)) {
        return "red";
      }
    }

    return null;
  }

  String _nutritionStatus(Map<String, dynamic> nutrition) {
    final calories = _toNum(nutrition["calories"]);
    final protein = _toNum(nutrition["protein"]);
    final carbs = _toNum(nutrition["carbs"]);
    final fat = _toNum(nutrition["fat"]);

    final caloriesTarget = _toNum(_profile["caloriesTarget"]);
    final proteinTarget = _toNum(_profile["proteinTarget"]);
    final carbsTarget = _toNum(_profile["carbsTarget"]);
    final fatTarget = _toNum(_profile["fatTarget"]);

    if ((caloriesTarget > 0 && calories > caloriesTarget) ||
        (proteinTarget > 0 && protein > proteinTarget) ||
        (carbsTarget > 0 && carbs > carbsTarget) ||
        (fatTarget > 0 && fat > fatTarget)) {
      return "orange";
    }

    return "green";
  }

  void _recalculateStatus() {
    final ingredientRisk = _ingredientRisk();
    if (ingredientRisk == "red") {
      if (mounted) {
        setState(() => _status = "red");
      }
      return;
    }

    final nutritionStatus = _nutritionStatus(_currentNutrition());
    if (mounted) {
      setState(() => _status = nutritionStatus);
    }
  }

  Future<void> _saveMealLog() async {
    setState(() => _saving = true);

    try {
      final nutrition = _currentNutrition();

      await MealLogService.createMealLog(
        mealName: (widget.meal["name"] ?? "").toString(),
        cuisine: (widget.meal["cuisine"] ?? "").toString(),
        category: (widget.meal["category"] ?? "").toString(),
        nutrition: nutrition,
        source: _useAiNutrition ? "menu-ai-nutrition" : "menu",
        eatenAt: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Meal saved to Meal Log")));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ ${e.toString().replaceFirst("Exception: ", "")}"),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String _displayValue(dynamic value) {
    if (value == null) return "-";
    if (value is num) {
      if (value == 0) return "-";
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }

    final parsed = num.tryParse(value.toString());
    if (parsed == null || parsed == 0) return "-";
    return parsed % 1 == 0
        ? parsed.toInt().toString()
        : parsed.toStringAsFixed(1);
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

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final nutrition = _currentNutrition();
    final ingredients = (meal["ingredients"] as List<dynamic>? ?? []);
    final dietTags = (meal["dietTags"] as List<dynamic>? ?? []);

    const Color lightGreen = Color(0xFFDFF5E1);
    const Color softGreen = Color(0xFFBFE7C1);
    const Color lightGray = Color(0xFFF3F4F6);
    const Color borderGray = Color(0xFFE0E0E0);
    const Color blackText = Colors.black;
    const Color darkGray = Color(0xFF666666);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: lightGreen,
        foregroundColor: blackText,
        centerTitle: true,
        title: Text(
          meal["name"] ?? "Meal Detail",
          style: const TextStyle(color: blackText, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: softGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: blackText,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(_status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(_status), color: _statusColor(_status)),
                      const SizedBox(width: 6),
                      Text(
                        _status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(_status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        icon: Icons.restaurant_menu,
                        label: "Cuisine",
                        value: meal["cuisine"] ?? "-",
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoChip(
                        icon: Icons.category_outlined,
                        label: "Category",
                        value: meal["category"] ?? "-",
                        bgColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _sectionCard(
            title: "Nutrition",
            icon: Icons.monitor_heart_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderGray),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _useAiNutrition ? "AI Based" : "Database Based",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _useAiNutrition,
                        onChanged: _onNutritionModeChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_useAiNutrition && _aiLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_useAiNutrition && _aiError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "AI nutrition failed: $_aiError",
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  _nutritionRow(
                    "Calories",
                    _displayValue(nutrition["calories"]),
                    "kcal",
                  ),
                  const Divider(height: 18),
                  _nutritionRow(
                    "Protein",
                    _displayValue(nutrition["protein"]),
                    "g",
                  ),
                  const Divider(height: 18),
                  _nutritionRow(
                    "Carbs",
                    _displayValue(nutrition["carbs"]),
                    "g",
                  ),
                  const Divider(height: 18),
                  _nutritionRow("Fat", _displayValue(nutrition["fat"]), "g"),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (dietTags.isNotEmpty)
            _sectionCard(
              title: "Diet Tags",
              icon: Icons.local_offer_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dietTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromARGB(255, 80, 220, 87),
                      ),
                    ),
                    child: Text(
                      tag.toString(),
                      style: const TextStyle(
                        color: blackText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          if (dietTags.isNotEmpty) const SizedBox(height: 16),

          _sectionCard(
            title: "Ingredients",
            icon: Icons.list_alt_outlined,
            child: ingredients.isEmpty
                ? const Text(
                    "No ingredients available",
                    style: TextStyle(color: darkGray),
                  )
                : Column(
                    children: ingredients.map((e) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderGray),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: blackText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveMealLog,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant),
              label: Text(_saving ? "Saving..." : "I Ate This"),
              style: ElevatedButton.styleFrom(
                backgroundColor: lightGreen,
                foregroundColor: blackText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: softGreen),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    const Color lightGray = Color(0xFFF3F4F6);
    const Color borderGray = Color(0xFFE0E0E0);
    const Color blackText = Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: blackText),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: blackText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  static Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    const Color blackText = Colors.black;
    const Color darkGray = Color(0xFF666666);
    const Color borderGray = Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGray),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: blackText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: blackText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _nutritionRow(String label, String value, String unit) {
    const Color blackText = Colors.black;
    const Color darkGray = Color(0xFF666666);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "$value $unit",
          style: const TextStyle(
            fontSize: 16,
            color: blackText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
