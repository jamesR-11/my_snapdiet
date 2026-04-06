const mongoose = require("mongoose");

const MealLogSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    mealName: { type: String, required: true },
    cuisine: { type: String, default: "" },
    category: { type: String, default: "" },

    nutrition: {
      calories: { type: Number, default: 0 },
      protein: { type: Number, default: 0 },
      carbs: { type: Number, default: 0 },
      fat: { type: Number, default: 0 },
    },

    source: { type: String, default: "menu" }, // menu | meal-photo
    eatenAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model("MealLog", MealLogSchema);