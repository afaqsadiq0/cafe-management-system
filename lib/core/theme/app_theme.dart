import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class AppTheme {
  // ☕ PREMIUM ARTISANAL CAFE PALETTE - Production Level
  
  // LIGHT MODE COLORS
  static const primaryColor = Color(0xFF1A1C1E); // Deep Midnight
  static const secondaryColor = Color(0xFFC68B59); // Warm Copper
  static const accentColor = Color(0xFF8B5E3C); // Roasted Coffee
  static const tileBgColor = Color(0xFFF9F7F2); // Warm Linen
  static const surfaceColor = Color(0xFFFFFFFF); // Pure White
  static const onSurfaceVariant = Color(0xFF5E6267); // Medium Gray
  static const successColor = Color(0xFF2D7D32); // Forest Green
  static const warningColor = Color(0xFFE65100); // Burnt Orange
  static const errorColor = Color(0xFFC62828); // Deep Red
  
  // DARK MODE COLORS
  static const darkBgColor = Color(0xFF0C0C0C); // True Obsidian
  static const darkSurfaceColor = Color(0xFF161616); // Soft Black
  static const darkCardColor = Color(0xFF1A1A1A); // Dark Card
  static const darkPrimaryText = Color(0xFFEAEAEA); // Ivory
  static const darkSecondaryText = Color(0xFFA0A0A0); // Silver Gray
  static const darkAccentColor = Color(0xFFE5B982); // Muted Gold
  
  static const double cardRadius = 20.0; 
  static const double buttonRadius = 16.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: tileBgColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: primaryColor,
      surfaceVariant: tileBgColor,
      onSurfaceVariant: onSurfaceVariant,
      outline: primaryColor.withOpacity(0.1),
    ),
    
    textTheme: GoogleFonts.hankenGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.ebGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.ebGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.ebGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: 1.2,
      ),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: tileBgColor,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      iconTheme: const IconThemeData(color: primaryColor),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: primaryColor.withOpacity(0.06)),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
      labelStyle: GoogleFonts.hankenGrotesk(color: onSurfaceVariant),
      hintStyle: GoogleFonts.hankenGrotesk(color: onSurfaceVariant.withOpacity(0.5)),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 3),
      ),
      labelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w500),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBgColor,
    colorScheme: ColorScheme.dark(
      primary: darkAccentColor,
      onPrimary: darkBgColor,
      secondary: darkAccentColor,
      onSecondary: darkBgColor,
      surface: darkSurfaceColor,
      onSurface: darkPrimaryText,
      surfaceVariant: darkBgColor,
      onSurfaceVariant: darkSecondaryText,
      outline: darkAccentColor.withOpacity(0.1),
    ),
    
    textTheme: GoogleFonts.hankenGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.ebGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: darkPrimaryText,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.ebGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: darkPrimaryText,
      ),
      displaySmall: GoogleFonts.ebGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: darkPrimaryText,
      ),
      headlineMedium: GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: darkPrimaryText,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkPrimaryText,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: darkPrimaryText,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: darkSecondaryText,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: darkPrimaryText,
        letterSpacing: 1.2,
      ),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: darkBgColor,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: darkPrimaryText,
      ),
      iconTheme: const IconThemeData(color: darkPrimaryText),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: darkAccentColor.withOpacity(0.08)),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccentColor,
        foregroundColor: darkBgColor,
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkAccentColor.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkAccentColor.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkAccentColor, width: 2),
      ),
      labelStyle: GoogleFonts.hankenGrotesk(color: darkSecondaryText),
      hintStyle: GoogleFonts.hankenGrotesk(color: darkSecondaryText.withOpacity(0.5)),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: darkAccentColor,
      unselectedLabelColor: darkSecondaryText,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: darkAccentColor, width: 3),
      ),
      labelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w500),
    ),
    
    dividerColor: darkAccentColor.withOpacity(0.1),
    iconTheme: const IconThemeData(color: darkPrimaryText),
  );
}
