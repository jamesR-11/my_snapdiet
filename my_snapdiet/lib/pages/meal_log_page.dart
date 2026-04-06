import 'package:flutter/material.dart';
import '../services/meal_log_service.dart';

class MealLogPage extends StatefulWidget {
  const MealLogPage({super.key});

  @override
  State<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends State<MealLogPage> {
  bool _loading = true;
  List<dynamic> _mealLogs = [];

  @override
  void initState() {
    super.initState();
    _loadMealLogs();
  }

  Future<void> _loadMealLogs() async {
    setState(() => _loading = true);

    try {
      final logs = await MealLogService.getMealLogs();
      if (!mounted) return;
      setState(() => _mealLogs = logs);
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

  List<Map<String, dynamic>> _getTodayLogs() {
    final now = DateTime.now();

    return _mealLogs
        .where((log) {
          try {
            final mealLog = log as Map<String, dynamic>;
            final eatenAtText = (mealLog["eatenAt"] ?? "").toString();

            if (eatenAtText.isEmpty) return false;

            final eatenAt = DateTime.parse(eatenAtText).toLocal();

            return eatenAt.year == now.year &&
                eatenAt.month == now.month &&
                eatenAt.day == now.day;
          } catch (_) {
            return false;
          }
        })
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day/$month/$year  $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final todayLogs = _getTodayLogs();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (todayLogs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMealLogs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                "No meal logs for today.\nSave a meal using 'I Ate This'.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMealLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: todayLogs.length,
        itemBuilder: (context, index) {
          final log = todayLogs[index];
          final nutrition = (log["nutrition"] ?? {}) as Map<String, dynamic>;
          final eatenAtText = (log["eatenAt"] ?? "").toString();
          final mealName = (log["mealName"] ?? "-").toString();
          final category = (log["category"] ?? "").toString();

          DateTime? eatenAt;
          try {
            eatenAt = DateTime.parse(eatenAtText).toLocal();
          } catch (_) {}

          final subtitle = eatenAt == null
              ? category
              : _formatDateTime(eatenAt);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.restaurant, color: Colors.green),
              title: Text(
                mealName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Text(
                    "Cal ${nutrition["calories"] ?? 0} | "
                    "P ${nutrition["protein"] ?? 0}g | "
                    "C ${nutrition["carbs"] ?? 0}g | "
                    "F ${nutrition["fat"] ?? 0}g",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
