const express = require("express");
const Meal = require("../models/Meal");

const router = express.Router();


// ✅ CREATE meal
router.post("/", async (req,res)=>{
  try{

    const meal = new Meal(req.body);
    await meal.save();

    res.json(meal);

  }catch(e){
    res.status(500).json({message:e.message});
  }
});


// ✅ GET all meals
router.get("/", async (req,res)=>{
  try{

    const meals = await Meal.find();

    res.json(meals);

  }catch(e){
    res.status(500).json({message:e.message});
  }
});


// ✅ SEARCH meal by name
router.get("/search", async (req,res)=>{
  try{

    const q = req.query.q;

    if(!q){
      return res.status(400).json({message:"Meal name query required"});
    }

    const meals = await Meal.find({
      name: { $regex: q, $options: "i" }
    });

    res.json(meals);

  }catch(e){
    res.status(500).json({message:e.message});
  }
});

module.exports = router;