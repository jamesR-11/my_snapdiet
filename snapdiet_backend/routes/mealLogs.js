const express = require("express");
const MealLog = require("../models/MealLog");
const auth = require("../middleware/auth");

const router = express.Router();

// CREATE meal log
router.post("/", auth, async (req, res) => {
  try {
    const { mealName, cuisine, category, nutrition, source, eatenAt } = req.body;

    const mealLog = new MealLog({
      user: req.userId,
      mealName,
      cuisine,
      category,
      nutrition: {
        calories: Number(nutrition?.calories || 0),
        protein: Number(nutrition?.protein || 0),
        carbs: Number(nutrition?.carbs || 0),
        fat: Number(nutrition?.fat || 0),
      },
      source: source || "menu",
      eatenAt: eatenAt ? new Date(eatenAt) : new Date(),
    });

    await mealLog.save();
    res.status(201).json(mealLog);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET all logs for logged-in user
router.get("/", auth, async (req, res) => {
  try {
    const logs = await MealLog.find({ user: req.userId }).sort({ eatenAt: -1 });
    res.json(logs);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;