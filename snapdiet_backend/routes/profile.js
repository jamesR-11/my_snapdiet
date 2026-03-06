const express = require("express");
const User = require("../models/User");
const auth = require("../middleware/auth");

const router = express.Router();

// ✅ GET /api/profile  -> returns user + profile
router.get("/", auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select("name email profile");
    if (!user) return res.status(404).json({ message: "User not found" });
    return res.json(user);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

// ✅ PUT /api/profile -> update profile fields (partial update)
router.put("/", auth, async (req, res) => {
  try {
    const body = req.body || {};

    // Helper conversions
    const toNum = (v) => {
      const n = Number(v);
      return Number.isFinite(n) ? n : 0;
    };
    const toStr = (v) => (v === undefined || v === null ? "" : String(v));
    const toStrArr = (v) => (Array.isArray(v) ? v.map((x) => String(x)) : []);

    // Build update object only with provided keys
    const set = {};

    // Basic info
    if ("fullName" in body) set["profile.fullName"] = toStr(body.fullName).trim();
    if ("age" in body) set["profile.age"] = toNum(body.age);
    if ("gender" in body) set["profile.gender"] = toStr(body.gender) || "Prefer not to say";
    if ("heightCm" in body) set["profile.heightCm"] = toNum(body.heightCm);
    if ("weightKg" in body) set["profile.weightKg"] = toNum(body.weightKg);

    // Diet preferences
    if ("goal" in body) set["profile.goal"] = toStr(body.goal);
    if ("dietType" in body) set["profile.dietType"] = toStr(body.dietType) || "Balanced";
    if ("activityLevel" in body) set["profile.activityLevel"] = toStr(body.activityLevel) || "Medium";
    if ("avoidFoods" in body) set["profile.avoidFoods"] = toStrArr(body.avoidFoods);

    // Allergies
    if ("allergies" in body) set["profile.allergies"] = toStrArr(body.allergies);

    // Daily targets
    if ("caloriesTarget" in body) set["profile.caloriesTarget"] = toNum(body.caloriesTarget);
    if ("proteinTarget" in body) set["profile.proteinTarget"] = toNum(body.proteinTarget);
    if ("carbsTarget" in body) set["profile.carbsTarget"] = toNum(body.carbsTarget);
    if ("fatTarget" in body) set["profile.fatTarget"] = toNum(body.fatTarget);

    // If nothing to update
    if (Object.keys(set).length === 0) {
      return res.status(400).json({ message: "No profile fields provided" });
    }
 if ("healthConditions" in body) set["profile.healthConditions"] = toStrArr(body.healthConditions);
    const updatedUser = await User.findByIdAndUpdate(
      req.userId,
      { $set: set },
      { new: true }
    ).select("name email profile");

    if (!updatedUser) return res.status(404).json({ message: "User not found" });

    return res.json(updatedUser);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

module.exports = router;