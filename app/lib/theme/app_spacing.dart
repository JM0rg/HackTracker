/// Standardized spacing values for consistent layout
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base spacing unit (8px)
  static const double unit = 8.0;

  // Common spacing values
  static const double xs = unit * 0.5;    // 4px
  static const double sm = unit;          // 8px
  static const double md = unit * 2;      // 16px
  static const double lg = unit * 3;      // 24px
  static const double xl = unit * 4;      // 32px
  static const double xxl = unit * 6;     // 48px

  // Specific use cases
  static const double cardPadding = md;           // 16px
  static const double cardPaddingSmall = sm;      // 8px
  static const double listItemPadding = md;       // 16px
  static const double screenPadding = md;         // 16px
  static const double buttonPadding = md;         // 16px
  static const double sectionSpacing = lg;        // 24px
  static const double elementSpacing = sm;        // 8px
}


