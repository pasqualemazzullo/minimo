import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AppTheme {
  // Base colors first
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color grey = Colors.grey;
  static const Color transparent = Colors.transparent;
  static const Color red = Colors.red;
  static const Color orange = Colors.orange;
  static const Color blue = Colors.blue;
  static const Color green = Colors.green;

  // Contextual colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey600 = Color(0xFF6B7280);
  static const Color grey700 = Color(0xFF4B5563);

  // Theme colors
  static const Color primaryColor = Color(0xFF006C59);
  static const Color chipBg = grey50;
  static const Color chipBorder = Color(0xFFF5F5F5);
  static const Color chipText = Color(0xFFA5A7A9);
  static const Color chipSelectedBg = Color(0xFF006C59);
  static const Color chipSelectedBorder = Color(0xFF006C59);
  static const Color chipSelectedText = Color(0xFFFFFFFF);
  static const Color unselectedText = Color(0xFFA5A7A9);
  static const Color unselectedBorder = Color(0xFFEDEDED);
  static const Color selectedBg = Color(0xFF006C59);
  static const Color selectedText = Color(0xFFFFFFFF);
  static const Color selectedBorder = Color(0xFF006C59);
  static const Color cardBorder = Color(0xFFF5F5F5);
  static const Color outOfStockLabel = Colors.amber;
  static const Color errorColor = Color(0xFF991B1B);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);

  // Alert colors
  static const Color alertRedBackground = Color(0xFFFEF2F2);
  static const Color alertRedText = Color(0xFF991B1B);
  static const Color alertRedBorder = Color(0xFFFCA5A5);

  static const Color alertYellowBackground = Color(0xFFFFFDE7);
  static const Color alertYellowText = Color(0xFFF59E00);
  static const Color alertYellowBorder = Color(0xFFFFF176);

  static const Color alertBlueBackground = Color(0xFFE3F2FD);
  static const Color alertBlueText = Color(0xFF1976D2);
  static const Color alertBlueBorder = Color(0xFF90CAF9);

  // Text Styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black54,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontFamily: AppConstants.fontFamily,
    color: grey600,
  );

  // Additional text styles for common use cases
  static const TextStyle textSmall = TextStyle(
    fontSize: 12,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle textSmallGrey = TextStyle(
    fontSize: 12,
    fontFamily: AppConstants.fontFamily,
    color: grey600,
  );

  static const TextStyle textSmallBold = TextStyle(
    fontSize: 12,
    fontFamily: AppConstants.fontFamily,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle textMedium = TextStyle(
    fontSize: 14,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle textMediumBold = TextStyle(
    fontSize: 14,
    fontFamily: AppConstants.fontFamily,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle textLarge = TextStyle(
    fontSize: 16,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle textLargeBold = TextStyle(
    fontSize: 16,
    fontFamily: AppConstants.fontFamily,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle textExtraLarge = TextStyle(
    fontSize: 24,
    fontFamily: AppConstants.fontFamily,
    color: Colors.black87,
  );

  static const TextStyle textExtraLargeBold = TextStyle(
    fontSize: 24,
    fontFamily: AppConstants.fontFamily,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.teal,
      primaryColor: primaryColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: AppConstants.fontFamily,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: AppConstants.fontFamily,
          color: Colors.black,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      highlightColor: const Color(0xFFF5F5F5),
      splashColor: const Color(0x22006C59),
    );
  }

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
  );

  // Input Decoration
  static InputDecoration getInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: unselectedBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: unselectedBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
