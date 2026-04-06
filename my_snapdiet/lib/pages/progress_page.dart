import 'package:flutter/material.dart';
import '../services/meal_log_service.dart';
import '../services/profile_service.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _loading = true;

  List<dynamic> _mealLogs = [];
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final logs = await MealLogService.getMealLogs();
      final profileData = await ProfileService.getProfile();

      if (!mounted) return;
      setState(() {
        _mealLogs = logs;
        _profile = (profileData["profile"] ?? {}) as Map<String, dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ ${e.toString().replaceFirst("Exception: ", "")}"),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final today = DateTime.now();

    num calories = 0;
    num protein = 0;
    num carbs = 0;
    num fat = 0;

    for (final item in _mealLogs) {
      final log = item as Map<String, dynamic>;
      final nutrition = (log["nutrition"] ?? {}) as Map<String, dynamic>;
      final eatenAtText = (log["eatenAt"] ?? "").toString();

      try {
        final dt = DateTime.parse(eatenAtText).toLocal();

        if (dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day) {
          calories += _toNum(nutrition["calories"]);
          protein += _toNum(nutrition["protein"]);
          carbs += _toNum(nutrition["carbs"]);
          fat += _toNum(nutrition["fat"]);
        }
      } catch (_) {}
    }

    final calTarget = _toNum(_profile["caloriesTarget"]);
    final proTarget = _toNum(_profile["proteinTarget"]);
    final carbTarget = _toNum(_profile["carbsTarget"]);
    final fatTarget = _toNum(_profile["fatTarget"]);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _progressCard("Calories", calories, calTarget, "kcal"),
          const SizedBox(height: 12),
          _progressCard("Protein", protein, proTarget, "g"),
          const SizedBox(height: 12),
          _progressCard("Carbs", carbs, carbTarget, "g"),
          const SizedBox(height: 12),
          _progressCard("Fat", fat, fatTarget, "g"),
        ],
      ),
    );
  }

  Widget _progressCard(String label, num current, num target, String unit) {
    final double progress = target > 0
        ? (current / target).clamp(0, 1).toDouble()
        : 0.0;

    final bool exceeded = target > 0 && current > target;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit",
                  style: TextStyle(
                    color: exceeded ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: exceeded ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
