import 'package:flutter/material.dart';

/// Centralized color palette for HackTracker app
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Brand colors (updated - brighter/more vibrant)
  static const primary = Color(0xFF14D68E); // Bright emerald
  static const secondary = Color(0xFF4AE4A8); // Bright mint

  // Backgrounds
  static const background = Color(0xFF0F172A); // Dark slate
  static const surface = Color(0xFF1E293B); // Slate

  // Borders & dividers
  static const border = Color(0xFF334155);

  // Text colors
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF64748B);
  static const textLight = Color(0xFFCBD5E1);

  // Status colors
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF14D68E);
  static const warning = Color(0xFFF97316); // Orange for in-progress/warnings
  static const info = Color(0xFF64748B); // Grey for postponed/inactive

  // Semantic colors for game statuses
  static const statusScheduled = primary; // Green
  static const statusInProgress = warning; // Orange
  static const statusFinal = success; // Green
  static const statusPostponed = info; // Grey

  // Player/User status colors
  static const linkedUserColor = success; // Green for linked accounts
  static const guestUserColor = info; // Grey for guest players
}

