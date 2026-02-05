import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Natural-Medical Color Palette (Sage & Cream)
  static const Color primaryColor = Color(
    0xFF6A9C89,
  ); // Sage Green (Calm, Natural)
  static const Color primaryDark = Color(0xFF16423C); // Deep Forest Green
  static const Color primaryLight = Color(0xFFC4DAD2); // Soft Mist Green

  static const Color accentColor = Color(0xFFFFAB91); // Soft Coral/Warm Peach

  static const Color background = Color(0xFFF9F9F7); // Warm Off-White (Paper)
  static const Color surface = Colors.white;

  static const Color textDark = Color(0xFF2D3436); // Soft Black
  static const Color textGrey = Color(0xFF636E72); // Grey

  static ThemeData getLight(Locale? locale) {
    // Select TextTheme based on locale
    TextTheme baseTextTheme = (locale?.languageCode == 'si')
        ? GoogleFonts.notoSansSinhalaTextTheme()
        : GoogleFonts.outfitTextTheme();

    // Select AppBar Title Style
    TextStyle appBarTitleStyle = (locale?.languageCode == 'si')
        ? GoogleFonts.notoSansSinhala(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textDark,
          )
        : GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textDark,
          );

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textGrey, fontSize: 14),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: appBarTitleStyle,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 10,
        shadowColor: Color(0xFF6A9C89).withOpacity(0.1),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: textGrey),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          textStyle:
              baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600) ??
              TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      useMaterial3: true,
    );
  }

  static ThemeData getDark(Locale? locale) {
    // Select TextTheme based on locale
    TextTheme baseTextTheme = (locale?.languageCode == 'si')
        ? GoogleFonts.notoSansSinhalaTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    TextStyle appBarTitleStyle = (locale?.languageCode == 'si')
        ? GoogleFonts.notoSansSinhala(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )
        : GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          );

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Color(0xFF1E1E1E),
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFF2C2C2C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: appBarTitleStyle,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Color(0xFF2C2C2C),
        elevation: 4,
        shadowColor: Colors.black54,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF333333),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white38),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          textStyle:
              baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600) ??
              TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      useMaterial3: true,
    );
  }
}
