import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileTab extends StatefulWidget {
  final String email;
  const ProfileTab({super.key, required this.email});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ---------- Dropdown option lists ----------
  static const List<String> genders = [
    "Male",
    "Female",
    "Other",
    "Prefer not to say",
  ];
  static const List<String> goals = [
    "Weight loss",
    "Maintain weight",
    "Muscle gain / Bodybuilding",
    "Body shape / Toning",
    "Athletic performance",
  ];
  static const List<String> dietTypes = [
    "Balanced",
    "Vegetarian",
    "Vegan",
    "Keto / Low-carb",
    "Halal",
    "Gluten-free",
    "High-protein",
    "Custom",
  ];
  static const List<String> activityLevels = ["Low", "Medium", "High"];

  static String safeValue(
    String current,
    List<String> options,
    String fallback,
  ) {
    final c = current.trim();
    return options.contains(c) ? c : fallback;
  }

  // ✅ Health options
  static const List<String> healthOptions = [
    "Diabetes / Pre-diabetes",
    "High blood pressure",
    "High cholesterol",
    "Kidney issues",
    "Gastric / Acid reflux",
    "Lactose intolerance",
    "Gluten sensitivity",
    "Weight management",
  ];

  // ---------- Common ----------
  bool _loading = true;
  bool _forceEdit = false;

  // Section edit toggles
  bool _editBasic = false;
  bool _editDiet = false;
  bool _editHealth = false; // ✅ new
  bool _editAllergies = false;
  bool _editTargets = false;

  bool _savingBasic = false;
  bool _savingDiet = false;
  bool _savingHealth = false; // ✅ new
  bool _savingAllergies = false;
  bool _savingTargets = false;

  // ---------- Basic Info ----------
  final _basicFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _gender = "Prefer not to say";

  // ---------- Diet Preference ----------
  final _dietFormKey = GlobalKey<FormState>();
  String _goal = "Weight loss";
  String _dietType = "Balanced";
  String _activityLevel = "Medium";
  final _avoidFoodCtrl = TextEditingController();
  List<String> _avoidFoods = [];

  // ✅ Health Conditions
  List<String> _healthConditions = [];

  // ---------- Allergies ----------
  final _allergyCtrl = TextEditingController();
  List<String> _allergies = [];

  // ---------- Targets ----------
  final _targetsFormKey = GlobalKey<FormState>();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  final List<String> _commonAllergies = const [
    "Peanuts",
    "Tree nuts",
    "Milk",
    "Eggs",
    "Soy",
    "Wheat/Gluten",
    "Fish",
    "Shellfish",
    "Sesame",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();

    _avoidFoodCtrl.dispose();
    _allergyCtrl.dispose();

    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  int _toInt(String v) => int.tryParse(v.trim()) ?? 0;

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ? "❌ $msg" : "✅ $msg")));
  }

  bool _profileIsEmpty(Map<String, dynamic> p) {
    final fullName = (p["fullName"] ?? "").toString().trim();
    final dietType = (p["dietType"] ?? "").toString().trim();
    final goal = (p["goal"] ?? "").toString().trim();
    final allergies = (p["allergies"] is List)
        ? (p["allergies"] as List).length
        : 0;

    final cal = _toInt((p["caloriesTarget"] ?? "0").toString());
    final pro = _toInt((p["proteinTarget"] ?? "0").toString());
    final carb = _toInt((p["carbsTarget"] ?? "0").toString());
    final fat = _toInt((p["fatTarget"] ?? "0").toString());

    // empty if ALL important values are empty/0
    return fullName.isEmpty &&
        dietType.isEmpty &&
        goal.isEmpty &&
        allergies == 0 &&
        cal == 0 &&
        pro == 0 &&
        carb == 0 &&
        fat == 0;
  }

  void _addChipFrom(TextEditingController ctrl, List<String> list) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    if (!list.contains(t)) setState(() => list.add(t));
    ctrl.clear();
  }

  // ---------- Load ----------
  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final data = await ProfileService.getProfile();
      final profile = (data["profile"] ?? {}) as Map<String, dynamic>;

      // Basic
      _nameCtrl.text = (profile["fullName"] ?? "").toString();
      _ageCtrl.text = (profile["age"] ?? "").toString();
      _heightCtrl.text = (profile["heightCm"] ?? "").toString();
      _weightCtrl.text = (profile["weightKg"] ?? "").toString();
      _gender = (profile["gender"] ?? "").toString();

      // Diet
      _goal = (profile["goal"] ?? "").toString();
      _dietType = (profile["dietType"] ?? "").toString();
      _activityLevel = (profile["activityLevel"] ?? "").toString();

      final af = profile["avoidFoods"];
      _avoidFoods = (af is List) ? af.map((e) => e.toString()).toList() : [];

      // ✅ Health
      final hc = profile["healthConditions"];
      _healthConditions = (hc is List)
          ? hc.map((e) => e.toString()).toList()
          : [];

      // Allergies
      final al = profile["allergies"];
      _allergies = (al is List) ? al.map((e) => e.toString()).toList() : [];

      // Targets
      _calCtrl.text = (profile["caloriesTarget"] ?? 0).toString();
      _proCtrl.text = (profile["proteinTarget"] ?? 0).toString();
      _carbCtrl.text = (profile["carbsTarget"] ?? 0).toString();
      _fatCtrl.text = (profile["fatTarget"] ?? 0).toString();

      // ✅ IMPORTANT: dropdown safe values
      _gender = safeValue(_gender, genders, "Prefer not to say");
      _goal = safeValue(_goal, goals, "Weight loss");
      _dietType = safeValue(_dietType, dietTypes, "Balanced");
      _activityLevel = safeValue(_activityLevel, activityLevels, "Medium");

      // First-time behaviour
      _forceEdit = _profileIsEmpty(profile);
      if (_forceEdit) {
        _editBasic = true;
        _editDiet = true;
        _editHealth = true;
        _editAllergies = true;
        _editTargets = true;
      } else {
        _editBasic = false;
        _editDiet = false;
        _editHealth = false;
        _editAllergies = false;
        _editTargets = false;
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Save per section ----------
  Future<void> _saveBasic() async {
    if (!_basicFormKey.currentState!.validate()) return;

    setState(() => _savingBasic = true);
    try {
      await ProfileService.updateProfile({
        "fullName": _nameCtrl.text.trim(),
        "age": _toInt(_ageCtrl.text),
        "gender": _gender,
        "heightCm": _toInt(_heightCtrl.text),
        "weightKg": _toInt(_weightCtrl.text),
      });
      if (!mounted) return;
      _snack("Basic info saved");
      setState(() => _editBasic = false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _savingBasic = false);
    }
  }

  Future<void> _saveDiet() async {
    if (!_dietFormKey.currentState!.validate()) return;

    setState(() => _savingDiet = true);
    try {
      await ProfileService.updateProfile({
        "goal": _goal,
        "dietType": _dietType,
        "activityLevel": _activityLevel,
        "avoidFoods": _avoidFoods,
      });
      if (!mounted) return;
      _snack("Diet preference saved");
      setState(() => _editDiet = false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _savingDiet = false);
    }
  }

  // ✅ Save Health Conditions
  Future<void> _saveHealth() async {
    setState(() => _savingHealth = true);
    try {
      await ProfileService.updateProfile({
        "healthConditions": _healthConditions,
      });
      if (!mounted) return;
      _snack("Health conditions saved");
      setState(() => _editHealth = false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _savingHealth = false);
    }
  }

  Future<void> _saveAllergies() async {
    setState(() => _savingAllergies = true);
    try {
      await ProfileService.updateProfile({"allergies": _allergies});
      if (!mounted) return;
      _snack("Allergies saved");
      setState(() => _editAllergies = false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _savingAllergies = false);
    }
  }

  Future<void> _saveTargets() async {
    if (!_targetsFormKey.currentState!.validate()) return;

    setState(() => _savingTargets = true);
    try {
      await ProfileService.updateProfile({
        "caloriesTarget": _toInt(_calCtrl.text),
        "proteinTarget": _toInt(_proCtrl.text),
        "carbsTarget": _toInt(_carbCtrl.text),
        "fatTarget": _toInt(_fatCtrl.text),
      });
      if (!mounted) return;
      _snack("Targets saved");
      setState(() => _editTargets = false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _savingTargets = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 22, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.email,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: "Refresh",
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_forceEdit) ...[
          const SizedBox(height: 10),
          const Text(
            "Please complete your profile (first time).",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),

        _basicInfoCard(),
        const SizedBox(height: 12),
        _dietCard(),
        const SizedBox(height: 12),
        _healthCard(), // ✅ new section
        const SizedBox(height: 12),
        _allergiesCard(),
        const SizedBox(height: 12),
        _targetsCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _basicInfoCard() {
    return _card(
      title: "Basic Info",
      editing: _editBasic,
      onEdit: () => setState(() => _editBasic = true),
      onCancel: () => setState(() => _editBasic = false),
      view: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowText("Full Name", _nameCtrl.text.isEmpty ? "-" : _nameCtrl.text),
          _rowText("Gender", _gender),
          _rowText("Age", _ageCtrl.text.isEmpty ? "-" : _ageCtrl.text),
          _rowText(
            "Height (cm)",
            _heightCtrl.text.isEmpty ? "-" : _heightCtrl.text,
          ),
          _rowText(
            "Weight (kg)",
            _weightCtrl.text.isEmpty ? "-" : _weightCtrl.text,
          ),
        ],
      ),
      edit: Form(
        key: _basicFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? "").trim().isEmpty ? "Name required" : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: safeValue(_gender, genders, "Prefer not to say"),
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _gender = v ?? "Prefer not to say"),
              decoration: const InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Age",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Height (cm)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Weight (kg)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _saveButton(_savingBasic, _saveBasic, "Save Basic Info"),
          ],
        ),
      ),
    );
  }

  Widget _dietCard() {
    return _card(
      title: "Diet Preference & Goal",
      editing: _editDiet,
      onEdit: () => setState(() => _editDiet = true),
      onCancel: () => setState(() => _editDiet = false),
      view: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowText("Goal", _goal),
          _rowText("Diet type", _dietType),
          _rowText("Activity level", _activityLevel),
          const SizedBox(height: 6),
          const Text(
            "Avoid foods",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _avoidFoods.isEmpty
              ? const Text("-")
              : Wrap(
                  spacing: 8,
                  children: _avoidFoods
                      .map((x) => Chip(label: Text(x)))
                      .toList(),
                ),
        ],
      ),
      edit: Form(
        key: _dietFormKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: safeValue(_goal, goals, "Weight loss"),
              items: goals
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _goal = v ?? "Weight loss"),
              decoration: const InputDecoration(
                labelText: "Your goal",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: safeValue(_dietType, dietTypes, "Balanced"),
              items: dietTypes
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _dietType = v ?? "Balanced"),
              decoration: const InputDecoration(
                labelText: "Diet type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: safeValue(_activityLevel, activityLevels, "Medium"),
              items: activityLevels
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _activityLevel = v ?? "Medium"),
              decoration: const InputDecoration(
                labelText: "Activity level",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _avoidFoodCtrl,
                    decoration: const InputDecoration(
                      labelText: "Avoid foods (e.g., sugar, pork)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _addChipFrom(_avoidFoodCtrl, _avoidFoods),
                    child: const Text("Add"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _avoidFoods
                  .map(
                    (x) => Chip(
                      label: Text(x),
                      onDeleted: () => setState(() => _avoidFoods.remove(x)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _saveButton(_savingDiet, _saveDiet, "Save Diet Preference"),
          ],
        ),
      ),
    );
  }

  // ✅ Health Conditions card
  Widget _healthCard() {
    return _card(
      title: "Health Conditions",
      editing: _editHealth,
      onEdit: () => setState(() => _editHealth = true),
      onCancel: () => setState(() => _editHealth = false),
      view: _healthConditions.isEmpty
          ? const Text("-")
          : Wrap(
              spacing: 8,
              children: _healthConditions
                  .map((x) => Chip(label: Text(x)))
                  .toList(),
            ),
      edit: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select any that apply:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: healthOptions.map((h) {
              final selected = _healthConditions.contains(h);
              return FilterChip(
                label: Text(h),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _healthConditions.remove(h);
                    } else {
                      _healthConditions.add(h);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _saveButton(_savingHealth, _saveHealth, "Save Health Conditions"),
        ],
      ),
    );
  }

  Widget _allergiesCard() {
    return _card(
      title: "Allergies",
      editing: _editAllergies,
      onEdit: () => setState(() => _editAllergies = true),
      onCancel: () => setState(() => _editAllergies = false),
      view: _allergies.isEmpty
          ? const Text("-")
          : Wrap(
              spacing: 8,
              children: _allergies.map((a) => Chip(label: Text(a))).toList(),
            ),
      edit: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tap to add/remove:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _commonAllergies.map((a) {
              final selected = _allergies.contains(a);
              return FilterChip(
                label: Text(a),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _allergies.remove(a);
                    } else {
                      _allergies.add(a);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _allergyCtrl,
                  decoration: const InputDecoration(
                    labelText: "Add custom allergy",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _addChipFrom(_allergyCtrl, _allergies),
                  child: const Text("Add"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _allergies
                .map(
                  (a) => Chip(
                    label: Text(a),
                    onDeleted: () => setState(() => _allergies.remove(a)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _saveButton(_savingAllergies, _saveAllergies, "Save Allergies"),
        ],
      ),
    );
  }

  Widget _targetsCard() {
    String? numValidator(String? v) {
      final t = (v ?? "").trim();
      if (t.isEmpty) return null;
      final n = int.tryParse(t);
      if (n == null || n < 0) return "Enter a valid number";
      return null;
    }

    return _card(
      title: "Daily Nutrition Targets",
      editing: _editTargets,
      onEdit: () => setState(() => _editTargets = true),
      onCancel: () => setState(() => _editTargets = false),
      view: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowText("Calories", "${_toInt(_calCtrl.text)} kcal/day"),
          _rowText("Protein", "${_toInt(_proCtrl.text)} g/day"),
          _rowText("Carbs", "${_toInt(_carbCtrl.text)} g/day"),
          _rowText("Fat", "${_toInt(_fatCtrl.text)} g/day"),
        ],
      ),
      edit: Form(
        key: _targetsFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Calories (kcal/day)",
                border: OutlineInputBorder(),
              ),
              validator: numValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _proCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Protein (g/day)",
                border: OutlineInputBorder(),
              ),
              validator: numValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _carbCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Carbs (g/day)",
                border: OutlineInputBorder(),
              ),
              validator: numValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fatCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Fat (g/day)",
                border: OutlineInputBorder(),
              ),
              validator: numValidator,
            ),
            const SizedBox(height: 12),
            _saveButton(_savingTargets, _saveTargets, "Save Targets"),
          ],
        ),
      ),
    );
  }

  // ---------- Small UI helpers ----------
  Widget _card({
    required String title,
    required bool editing,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required Widget view,
    required Widget edit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              title: title,
              editing: editing,
              onEdit: onEdit,
              onCancel: onCancel,
            ),
            const SizedBox(height: 10),
            editing ? edit : view,
          ],
        ),
      ),
    );
  }

  Widget _saveButton(bool saving, Future<void> Function() onSave, String text) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: saving ? null : onSave,
        child: saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required bool editing,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (!editing)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Edit"),
          )
        else
          TextButton(onPressed: onCancel, child: const Text("Cancel")),
      ],
    );
  }

  Widget _rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
