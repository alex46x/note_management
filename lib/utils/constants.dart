import 'package:flutter/material.dart';

class AppConstants {
  // Collection Name
  static const String notesCollection = 'notes';

  // Card Borders & Corner Radius
  static const double cardRadius = 16.0;
  static const double inputRadius = 12.0;
  static const double buttonRadius = 24.0;

  // Padding & Spacing (8dp system)
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // Custom Color Palette - Indigo & Slate
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6366F1); // Indigo 500
  static const Color lightPrimaryContainer = Color(0xFFE0E7FF); // Indigo 100
  static const Color lightOnPrimaryContainer = Color(0xFF312E81); // Indigo 900
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Premium Dark Mode Colors (Deep Obsidian & Charcoal)
  static const Color darkBg = Color(0xFF090A0F); // Deep Obsidian Black
  static const Color darkSurface = Color(0xFF16171F); // Premium Charcoal
  static const Color darkPrimary = Color(0xFF3B82F6); // Royal Blue Accent
  static const Color darkPrimaryContainer = Color(0xFF1D2433); // Soft Navy/Indigo Container
  static const Color darkOnPrimaryContainer = Color(0xFF93C5FD); // Soft Light Blue text
  static const Color darkTextPrimary = Color(0xFFF3F4F6); // Crisp Light Grey
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Muted Neutral Grey
  static const Color darkBorder = Color(0xFF232530); // Crisp dark border line

  // Semantic Colors
  static const Color colorError = Color(0xFFEF4444); // Red 500
  static const Color colorSuccess = Color(0xFF10B981); // Emerald 500
  static const Color colorWarning = Color(0xFFF59E0B); // Amber 500

  // Note Card Colors (Pastel tones for categorization, soft & beautiful)
  static final List<Color> lightNoteColors = [
    const Color(0xFFFFFFFF), // White
    const Color(0xFFFEF3C7), // Amber 100
    const Color(0xFFD1FAE5), // Emerald 100
    const Color(0xFFDBEAFE), // Blue 100
    const Color(0xFFF3E8FF), // Purple 100
    const Color(0xFFFCE7F3), // Pink 100
  ];

  static final List<Color> darkNoteColors = [
    const Color(0xFF16171F), // Deep Charcoal
    const Color(0xFF221C11), // Deep Amber/Gold
    const Color(0xFF11221A), // Deep Forest Emerald
    const Color(0xFF111A2E), // Deep Ocean Blue
    const Color(0xFF1B1229), // Deep Royal Purple
    const Color(0xFF281116), // Deep Crimson Red
  ];

  /// Get soft background color based on note ID or index
  static Color getNoteColor(String noteId, bool isDarkMode) {
    // Generate a simple hash from noteId to consistently select a color
    final int hash = noteId.runes.fold(0, (prev, element) => prev + element);
    if (isDarkMode) {
      return darkNoteColors[hash % darkNoteColors.length];
    } else {
      return lightNoteColors[hash % lightNoteColors.length];
    }
  }
}
