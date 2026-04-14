import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_style.dart';

class ThemeProvider extends ChangeNotifier {
  bool currentTheme = true; // Default to dark mode for trading app

  ThemeMode get themeMode {
    return currentTheme ? ThemeMode.dark : ThemeMode.light;
  }

  changeTheme(bool theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', theme);
    currentTheme = theme;
    notifyListeners();
  }

  initialize() async {
    final prefs = await SharedPreferences.getInstance();
    currentTheme = prefs.getBool('darkMode') ?? true;
    notifyListeners();
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    useMaterial3: false,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
    scaffoldBackgroundColor: Styles.textColorDark,
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: Styles.cardDark,
    colorScheme: ColorScheme(
      primary: Styles.primaryColor,
      secondary: Styles.primaryColor,
      surface: Colors.black,
      error: Colors.red,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.redAccent,
      brightness: Brightness.dark,
    ),
    dividerColor: Colors.white24,
    textTheme: GoogleFonts.interTextTheme(),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(width: 1, color: Styles.primaryColor)),
      checkColor: WidgetStateProperty.all(Colors.white),
      fillColor: WidgetStateProperty.all(Styles.primaryColor),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
  );

  static final lightTheme = ThemeData(
      useMaterial3: false,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.transparent),
      scaffoldBackgroundColor: Styles.bgColor,
      primaryColor: Styles.primaryColor,
      iconTheme: const IconThemeData(color: Colors.black),
      dividerColor: Styles.viewLineColor,
      cardColor: Styles.cardLight,
      colorScheme: ColorScheme(
        primary: Styles.primaryColor,
        secondary: Styles.primaryColor,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.redAccent,
        brightness: Brightness.light,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(width: 1, color: Styles.primaryColor)),
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(Styles.primaryColor),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      textTheme: GoogleFonts.interTextTheme(),
  );
}
