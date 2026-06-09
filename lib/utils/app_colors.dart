import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF1A3C5E);
  static const Color gold = Color(0xFFC9A84C);
  static const Color lightBlue = Color(0xFFEEF4FF);
  static const Color background = Color(0xFFF0F5FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF9DB0C8);
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF2E7D32);
  static const Color darkText = Color(0xFF0D1F35);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white);
  static const TextStyle subheading = TextStyle(
    fontSize: 13, color: Color(0xFF8BAECF));
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.darkText);
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted,
    letterSpacing: 0.5);
  static const TextStyle button = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white);
}
