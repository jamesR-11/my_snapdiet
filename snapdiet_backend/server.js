require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const profileRoutes = require("./routes/profile");

const authRoutes = require("./routes/auth");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => res.send("SnapDiet API running ✅"));

app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);


mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB connected"))
  .catch((e) => console.error("❌ MongoDB connection error:", e.message));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ Server started on http://localhost:${PORT}`));