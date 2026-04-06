const mongoose = require("mongoose");

const MealSchema = new mongoose.Schema(
{
  name: String,
  cuisine: String,
  category: String,

  ingredients: [String],

  nutrition: {
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number
  },

  dietTags: [String],     
  allergens: [String],

  vegetarian: Boolean,
  vegan: Boolean,
  halal: Boolean
},
{ timestamps: true }
);

module.exports = mongoose.model("Meal", MealSchema);