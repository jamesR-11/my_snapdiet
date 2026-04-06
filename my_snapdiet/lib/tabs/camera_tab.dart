import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/ai_meal_detail_page.dart';
import '../services/logmeal_service.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _loading = false;
  bool _showResults = false; // ✅ added

  MealCandidate? _topMeal1;
  MealCandidate? _topMeal2;

  Future<void> _takePhoto() async {
    final XFile? xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (xfile == null) return;

    setState(() {
      _image = File(xfile.path);
      _topMeal1 = null;
      _topMeal2 = null;
      _showResults = false; // ✅ hide results when new photo taken
    });
  }

  Future<void> _analyzePhoto() async {
    if (_image == null) return;

    if (!LogMealService.hasToken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add your LogMeal token first")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _topMeal1 = null;
      _topMeal2 = null;
      _showResults = false;
    });

    try {
      final recognition = await LogMealService.recognizeMeal(_image!);
      final meals = LogMealService.extractTopMealCandidates(recognition);

      setState(() {
        _topMeal1 = meals.isNotEmpty ? meals[0] : null;
        _topMeal2 = meals.length > 1 ? meals[1] : null;
        _showResults = true; // ✅ show only after analyze
      });

      if (_topMeal1 == null && _topMeal2 == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No meals detected")));
      }
    } catch (e) {
      setState(() {
        _showResults = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: ${e.toString().replaceFirst("Exception: ", "")}",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMealDetail(MealCandidate candidate) async {
    if (_image == null) return;

    try {
      setState(() => _loading = true);

      final recognition = await LogMealService.recognizeMeal(_image!);
      final imageId = LogMealService.extractImageId(recognition);

      await LogMealService.confirmDish(imageId: imageId, candidate: candidate);

      final ingredientsResponse = await LogMealService.getIngredients(imageId);
      final nutritionResponse = await LogMealService.getNutrition(imageId);

      final ingredients = LogMealService.extractIngredients(
        ingredientsResponse,
      );
      final nutrition = LogMealService.extractNutrition(nutritionResponse);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RealMealDetailPage(
            mealName: candidate.name,
            ingredients: ingredients,
            nutrition: nutrition,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: ${e.toString().replaceFirst("Exception: ", "")}",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _mealTile(MealCandidate? candidate, String label) {
    return InkWell(
      onTap: candidate == null || _loading
          ? null
          : () => _openMealDetail(candidate),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    candidate?.name ?? "-",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (candidate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      "Confidence: ${(candidate.prob * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _image == null
                  ? const Text(
                      'No photo yet.\nTap "Take Photo".',
                      textAlign: TextAlign.center,
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
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_image == null || _loading) ? null : _analyzePhoto,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(_loading ? 'Analyzing...' : 'Analyze Meal'),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ show results only after analyze
          if (_showResults)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: _resultCard(
                  title: "Analyze Meals",
                  child: Column(
                    children: [
                      _mealTile(_topMeal1, "Top Meal 1"),
                      _mealTile(_topMeal2, "Top Meal 2"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
