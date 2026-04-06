import 'package:flutter/material.dart';
import '../services/meal_log_service.dart';

class RealMealDetailPage extends StatefulWidget {
  final String mealName;
  final List<String> ingredients;
  final Map<String, dynamic> nutrition;

  const RealMealDetailPage({
    super.key,
    required this.mealName,
    required this.ingredients,
    required this.nutrition,
  });

  @override
  State<RealMealDetailPage> createState() => _RealMealDetailPageState();
}

class _RealMealDetailPageState extends State<RealMealDetailPage> {
  bool _saving = false;

  Future<void> _saveMeal() async {
    setState(() => _saving = true);

    try {
      await MealLogService.createMealLog(
        mealName: widget.mealName,
        cuisine: "Detected Meal",
        category: "non_veg",
        nutrition: {
          "calories": widget.nutrition["calories"] ?? 0,
          "protein": widget.nutrition["protein"] ?? 0,
          "carbs": widget.nutrition["carbs"] ?? 0,
          "fat": widget.nutrition["fat"] ?? 0,
        },
        source: "meal-photo",
        eatenAt: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Meal saved successfully")),
      );

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

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.nutrition;

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
          widget.mealName,
          style: const TextStyle(color: blackText, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top meal card
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
                  widget.mealName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: blackText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        icon: Icons.camera_alt_outlined,
                        label: "Source",
                        value: "Meal Photo",
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoChip(
                        icon: Icons.restaurant_outlined,
                        label: "Type",
                        value: "Detected Meal",
                        bgColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Nutrition section
          _sectionCard(
            title: "Nutrition",
            icon: Icons.monitor_heart_outlined,
            child: Column(
              children: [
                _nutritionRow(
                  "Calories",
                  nutrition["calories"],
                  "kcal",
                  darkGray,
                  blackText,
                ),
                const Divider(height: 18),
                _nutritionRow(
                  "Protein",
                  nutrition["protein"],
                  "g",
                  darkGray,
                  blackText,
                ),
                const Divider(height: 18),
                _nutritionRow(
                  "Carbs",
                  nutrition["carbs"],
                  "g",
                  darkGray,
                  blackText,
                ),
                const Divider(height: 18),
                _nutritionRow(
                  "Fat",
                  nutrition["fat"],
                  "g",
                  darkGray,
                  blackText,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ingredients section
          _sectionCard(
            title: "Ingredients",
            icon: Icons.list_alt_outlined,
            child: widget.ingredients.isEmpty
                ? const Text(
                    "No ingredients available",
                    style: TextStyle(color: darkGray),
                  )
                : Column(
                    children: widget.ingredients.map((e) {
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
                                e,
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

          // Save button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveMeal,
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
                  value,
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

  static Widget _nutritionRow(
    String label,
    dynamic value,
    String unit,
    Color darkGray,
    Color blackText,
  ) {
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "${n.toStringAsFixed(1)} $unit",
          style: TextStyle(
            fontSize: 16,
            color: blackText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
