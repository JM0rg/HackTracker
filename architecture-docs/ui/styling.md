# Styling Documentation

**Part of:** [UI_ARCHITECTURE.md](../UI_ARCHITECTURE.md) - Complete frontend implementation guide

This document provides a comprehensive guide to HackTracker's theming system, including Material 3 integration, custom extensions, and responsive design patterns.

---

## Table of Contents

1. [Theme Structure](#theme-structure)
2. [Text Style Hierarchy](#text-style-hierarchy)
3. [Color System](#color-system)
4. [Decoration Patterns](#decoration-patterns)
5. [Responsive Design Utilities](#responsive-design-utilities)
6. [Migration from Inline Styles](#migration-from-inline-styles)

---

## Theme Structure

### Material 3 Theme Configuration

HackTracker uses **Material 3** as the foundation with custom styling:

```dart
// app/lib/theme/app_theme.dart
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        textStyle: GoogleFonts.tektur(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.tektur(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    extensions: [
      CustomTextStyles.dark,
    ],
  );
}
```

### Theme Application

```dart
// app/lib/main.dart
class HackTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HackTracker',
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}
```

### Theme Access Patterns

```dart
// Standard Material 3 styles
Theme.of(context).textTheme.headlineLarge
Theme.of(context).textTheme.bodyMedium
Theme.of(context).textTheme.labelSmall

// Custom extension styles
Theme.of(context).extension<CustomTextStyles>()!.toggleButtonLabel
Theme.of(context).extension<CustomTextStyles>()!.statusIndicator
Theme.of(context).extension<CustomTextStyles>()!.appBarTitle
```

---

## Text Style Hierarchy

### Material 3 Text Scale

HackTracker implements the complete Material 3 text scale using **Tektur font**:

```dart
TextTheme _buildTextTheme() {
  return TextTheme(
    // Display styles (largest)
    displayLarge: GoogleFonts.tektur(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.tektur(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.25,
    ),
    displaySmall: GoogleFonts.tektur(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    
    // Headline styles
    headlineLarge: GoogleFonts.tektur(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    headlineMedium: GoogleFonts.tektur(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    headlineSmall: GoogleFonts.tektur(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    
    // Title styles
    titleLarge: GoogleFonts.tektur(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    titleMedium: GoogleFonts.tektur(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    ),
    titleSmall: GoogleFonts.tektur(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    ),
    
    // Body styles
    bodyLarge: GoogleFonts.tektur(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.tektur(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.tektur(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    ),
    
    // Label styles
    labelLarge: GoogleFonts.tektur(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.tektur(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.tektur(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}
```

### Custom Text Styles Extension

For styles that don't fit Material's standard categories:

```dart
// app/lib/theme/custom_text_styles.dart
class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  final TextStyle toggleButtonLabel;
  final TextStyle statusIndicator;
  final TextStyle appBarTitle;
  final TextStyle sectionHeader;
  final TextStyle errorMessage;
  
  const CustomTextStyles({
    required this.toggleButtonLabel,
    required this.statusIndicator,
    required this.appBarTitle,
    required this.sectionHeader,
    required this.errorMessage,
  });
  
  @override
  CustomTextStyles copyWith({
    TextStyle? toggleButtonLabel,
    TextStyle? statusIndicator,
    TextStyle? appBarTitle,
    TextStyle? sectionHeader,
    TextStyle? errorMessage,
  }) {
    return CustomTextStyles(
      toggleButtonLabel: toggleButtonLabel ?? this.toggleButtonLabel,
      statusIndicator: statusIndicator ?? this.statusIndicator,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  CustomTextStyles lerp(ThemeExtension<CustomTextStyles>? other, double t) {
    if (other is! CustomTextStyles) return this;
    
    return CustomTextStyles(
      toggleButtonLabel: TextStyle.lerp(toggleButtonLabel, other.toggleButtonLabel, t)!,
      statusIndicator: TextStyle.lerp(statusIndicator, other.statusIndicator, t)!,
      appBarTitle: TextStyle.lerp(appBarTitle, other.appBarTitle, t)!,
      sectionHeader: TextStyle.lerp(sectionHeader, other.sectionHeader, t)!,
      errorMessage: TextStyle.lerp(errorMessage, other.errorMessage, t)!,
    );
  }
  
  static const CustomTextStyles dark = CustomTextStyles(
    toggleButtonLabel: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
    ),
    statusIndicator: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
    ),
    appBarTitle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    sectionHeader: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    errorMessage: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.error,
      letterSpacing: 0.25,
    ),
  );
}
```

### Text Style Usage Patterns

```dart
// In widgets - use theme styles instead of inline styles
class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Use Material 3 styles
        Text(
          'Main Title',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        
        // Use custom extension styles
        Text(
          'Section Header',
          style: Theme.of(context).extension<CustomTextStyles>()!.sectionHeader,
        ),
        
        // Use body text
        Text(
          'Body content goes here',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        // Use label text
        Text(
          'Small label',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
```

---

## Color System

### AppColors - Centralized Color Palette

```dart
// app/lib/theme/app_colors.dart
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Brand colors (bright/neon theme)
  static const primary = Color(0xFF14D68E);     // Bright emerald
  static const secondary = Color(0xFF4AE4A8);   // Bright mint

  // Backgrounds
  static const background = Color(0xFF0F172A);  // Dark slate
  static const surface = Color(0xFF1E293B);     // Slate

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
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
}
```

### Color Usage Patterns

```dart
// Use AppColors instead of hardcoded colors
Container(
  color: AppColors.surface,           // Background
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Content',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// Status-based colors
Container(
  decoration: BoxDecoration(
    color: AppColors.success,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'Success',
    style: TextStyle(color: AppColors.background),
  ),
)
```

### Color Scheme Integration

```dart
// Material 3 ColorScheme integration
ThemeData _buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    // Custom colors override Material defaults
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
    ),
  );
}
```

---

## Decoration Patterns

### DecorationStyles Utility Class

```dart
// app/lib/theme/decoration_styles.dart
class DecorationStyles {
  // Primary border decoration
  static BoxDecoration primaryBorder() {
    return BoxDecoration(
      border: Border.all(color: AppColors.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  // Surface container decoration
  static BoxDecoration surfaceContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }
  
  // Error container decoration
  static BoxDecoration errorContainer() {
    return BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.error),
    );
  }
  
  // Status container decoration
  static BoxDecoration statusContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    );
  }
  
  // Card decoration
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // Info box decoration
  static BoxDecoration infoBox() {
    return BoxDecoration(
      color: AppColors.info.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.info),
    );
  }
  
  // Password requirements decoration
  static BoxDecoration passwordRequirements() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    );
  }
}
```

### Decoration Usage Patterns

```dart
// Use DecorationStyles instead of inline BoxDecoration
Container(
  decoration: DecorationStyles.surfaceContainer(),
  child: Text('Content'),
)

// Error states
Container(
  decoration: DecorationStyles.errorContainer(),
  child: Text(
    'Error message',
    style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
  ),
)

// Status indicators
Container(
  decoration: DecorationStyles.statusContainer(),
  child: Row(
    children: [
      Icon(Icons.check, color: AppColors.success),
      Text('Active'),
    ],
  ),
)
```

### Common Decoration Patterns

```dart
// Form field containers
Container(
  decoration: DecorationStyles.surfaceContainer(),
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      TextField(/* ... */),
      TextField(/* ... */),
    ],
  ),
)

// Status chips
Container(
  decoration: DecorationStyles.statusContainer(),
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: Text(
    'Active',
    style: Theme.of(context).extension<CustomTextStyles>()!.statusIndicator,
  ),
)

// Error messages
Container(
  decoration: DecorationStyles.errorContainer(),
  padding: EdgeInsets.all(12),
  child: Text(
    'Something went wrong',
    style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
  ),
)
```

---

## Responsive Design Utilities

### Screen Size Adaptation

```dart
// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
  static const double desktop = 1440;
}

// Responsive widget helper
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= Breakpoints.desktop && desktop != null) {
      return desktop!;
    } else if (screenWidth >= Breakpoints.tablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
```

### Responsive Layout Patterns

```dart
// Responsive column/row
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= Breakpoints.tablet) {
      return Row(children: children);
    } else {
      return Column(children: children);
    }
  }
}

// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.all(
        screenWidth >= Breakpoints.tablet ? 24.0 : 16.0,
      ),
      child: child,
    );
  }
}
```

### Responsive Dialog Sizing

```dart
// FormDialog responsive width
class FormDialog extends StatelessWidget {
  static double _getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.8; // 80% of screen width
    return maxWidth.clamp(300.0, 600.0); // Min 300px, max 600px
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: _getDialogWidth(context),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog content
          ],
        ),
      ),
    );
  }
}
```

### Responsive Text Sizing

```dart
// Responsive text scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth >= Breakpoints.tablet ? 1.2 : 1.0;
    
    return Text(
      text,
      style: style?.copyWith(
        fontSize: (style?.fontSize ?? 14) * scaleFactor,
      ),
    );
  }
}
```

---

## Migration from Inline Styles

### Before: Inline Styles

```dart
// Bad: Inline styles
Container(
  decoration: BoxDecoration(
    color: Color(0xFF1E293B),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFF334155)),
  ),
  child: Text(
    'Content',
    style: GoogleFonts.tektur(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE2E8F0),
    ),
  ),
)
```

### After: Theme-Based Styles

```dart
// Good: Theme-based styles
Container(
  decoration: DecorationStyles.surfaceContainer(),
  child: Text(
    'Content',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)
```

### Migration Checklist

#### 1. Replace GoogleFonts.tektur() calls

```dart
// Before
Text(
  'Title',
  style: GoogleFonts.tektur(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
)

// After
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineSmall,
)
```

#### 2. Replace BoxDecoration instances

```dart
// Before
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
  ),
)

// After
Container(
  decoration: DecorationStyles.surfaceContainer(),
)
```

#### 3. Replace hardcoded colors

```dart
// Before
Container(
  color: Color(0xFF1E293B),
  child: Text(
    'Text',
    style: TextStyle(color: Color(0xFFE2E8F0)),
  ),
)

// After
Container(
  color: AppColors.surface,
  child: Text(
    'Text',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

#### 4. Remove unused imports

```dart
// Remove this import from files that no longer use GoogleFonts
import 'package:google_fonts/google_fonts.dart';
```

### Migration Tools

#### Automated Migration Script

```bash
# Find all GoogleFonts.tektur() calls
grep -r "GoogleFonts.tektur" app/lib

# Find all BoxDecoration instances
grep -r "BoxDecoration" app/lib

# Find all hardcoded colors
grep -r "Color(0x" app/lib
```

#### Manual Migration Steps

1. **Identify inline styles** - Search for `GoogleFonts.tektur`, `BoxDecoration`, hardcoded colors
2. **Replace with theme styles** - Use `Theme.of(context).textTheme.*` or `CustomTextStyles`
3. **Replace decorations** - Use `DecorationStyles.*` methods
4. **Replace colors** - Use `AppColors.*` constants
5. **Remove unused imports** - Remove `google_fonts` imports where no longer needed
6. **Test visual consistency** - Verify UI looks identical after migration

---

## Theme Customization

### Adding New Text Styles

```dart
// Add to CustomTextStyles
class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  final TextStyle newCustomStyle;
  
  const CustomTextStyles({
    // ... existing styles
    required this.newCustomStyle,
  });
  
  // Add to factory constructors
  static const CustomTextStyles dark = CustomTextStyles(
    // ... existing styles
    newCustomStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
  );
}
```

### Adding New Decoration Styles

```dart
// Add to DecorationStyles
class DecorationStyles {
  static BoxDecoration newCustomDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary, width: 3),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
```

### Adding New Colors

```dart
// Add to AppColors
class AppColors {
  // ... existing colors
  static const accent = Color(0xFF8B5CF6);  // Purple accent
  static const highlight = Color(0xFFFBBF24); // Yellow highlight
}
```

---

## Accessibility Considerations

### Color Contrast

```dart
// Ensure sufficient contrast ratios
class AppColors {
  // High contrast text colors
  static const textPrimary = Color(0xFFE2E8F0);    // High contrast
  static const textSecondary = Color(0xFF94A3B8);  // Medium contrast
  static const textTertiary = Color(0xFF64748B);   // Lower contrast
}
```

### Text Scaling

```dart
// Support system text scaling
Text(
  'Content',
  style: Theme.of(context).textTheme.bodyMedium,
  // Flutter automatically handles text scaling
)
```

### Focus Indicators

```dart
// Ensure focus indicators are visible
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
    // Focus color automatically handled by Material 3
  ),
)
```

---

## Performance Considerations

### Theme Caching

```dart
// Theme is cached by Flutter automatically
// No performance impact from theme access
Theme.of(context).textTheme.headlineLarge
```

### Font Loading

```dart
// Google Fonts are cached after first load
// Subsequent uses have no performance impact
GoogleFonts.tektur(fontSize: 16)
```

### Decoration Reuse

```dart
// DecorationStyles methods return new instances
// Consider caching for frequently used decorations
class DecorationStyles {
  static final _surfaceContainer = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );
  
  static BoxDecoration surfaceContainer() => _surfaceContainer;
}
```

---

## Testing Styling

### Theme Testing

```dart
void main() {
  testWidgets('Theme should apply correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Text(
            'Test',
            style: Theme.of(tester.element(find.text('Test'))).textTheme.headlineLarge,
          ),
        ),
      ),
    );
    
    // Verify theme is applied
    expect(find.text('Test'), findsOneWidget);
  });
}
```

### Color Testing

```dart
void main() {
  test('AppColors should have correct values', () {
    expect(AppColors.primary, const Color(0xFF14D68E));
    expect(AppColors.background, const Color(0xFF0F172A));
    expect(AppColors.textPrimary, const Color(0xFFE2E8F0));
  });
}
```

### Responsive Testing

```dart
void main() {
  testWidgets('Responsive layout should adapt to screen size', (tester) async {
    // Test mobile size
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(ResponsiveWidget(mobile: Text('Mobile')));
    expect(find.text('Mobile'), findsOneWidget);
    
    // Test tablet size
    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(ResponsiveWidget(
      mobile: Text('Mobile'),
      tablet: Text('Tablet'),
    ));
    expect(find.text('Tablet'), findsOneWidget);
  });
}
```

---

## Summary

HackTracker's styling system provides:

- **Material 3 Foundation** - Modern Material Design with custom theming
- **Centralized Color Management** - AppColors for consistent color usage
- **Complete Text Scale** - Material 3 text styles with Tektur font
- **Custom Extensions** - CustomTextStyles for application-specific styles
- **Decoration Utilities** - DecorationStyles for common container patterns
- **Responsive Design** - Screen size adaptation and flexible layouts
- **Migration Support** - Clear patterns for moving from inline styles
- **Accessibility** - High contrast colors and text scaling support
- **Performance** - Efficient theme caching and font loading

The styling system provides a **comprehensive foundation** for consistent, accessible, and maintainable UI design while supporting **responsive layouts** and **theme customization**.
