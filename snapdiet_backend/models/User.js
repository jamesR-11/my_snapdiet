const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },

    // ✅ Full profile object for SnapDiet
    profile: {
  fullName: { type: String, default: "" },
  age: { type: Number, default: 0 },
  gender: { type: String, default: "Prefer not to say" },
  heightCm: { type: Number, default: 0 },
  weightKg: { type: Number, default: 0 },

  goal: { type: String, default: "" },
  dietType: { type: String, default: "Balanced" },
  activityLevel: { type: String, default: "Medium" },
  avoidFoods: { type: [String], default: [] },

  allergies: { type: [String], default: [] },

  caloriesTarget: { type: Number, default: 0 },
  proteinTarget: { type: Number, default: 0 },
  carbsTarget: { type: Number, default: 0 },
  fatTarget: { type: Number, default: 0 },

  healthConditions: { type: [String], default: [] },
}
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", UserSchema);