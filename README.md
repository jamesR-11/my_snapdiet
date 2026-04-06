# SnapDiet

SnapDiet is a mobile diet and meal analysis app built with **Flutter**, **Node.js**, and **MongoDB**.  
The app helps users scan menu images, detect meal names, check nutrition details, and compare meals with their diet profile.

## Features

- User registration and login
- Profile management
- Upload or capture menu images
- OCR-based text extraction from menus
- Meal search from database
- Nutrition information display
- Meal suitability status:
  - Green = suitable
  - Orange = moderate
  - Red = not suitable
- Meal log
- progress tracking

## Tech Stack

### Frontend
- Flutter
- Dart

### Backend
- Node.js

### Database
- MongoDB

### Other Tools / Packages
- Google ML Kit Text Recognition
- SharedPreferences
- HTTP package

## Project Structure

```bash

SnapDiet/
│
├── frontend/        # Flutter mobile application
│
├── backend/         # Node.js
│
└── README.md
