import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/otp24/otp24.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF3F7FA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const OTP24App());
}

class OTP24App extends StatelessWidget {
  const OTP24App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTP24HR HUB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFFEF5388),
        scaffoldBackgroundColor: const Color(0xFFF3F7FA),
        fontFamily: GoogleFonts.nunito().fontFamily,
        textTheme: GoogleFonts.nunitoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5388),
        ).copyWith(
          surface: Colors.white,
          onTertiary: const Color(0xFF45536D),
          surfaceTint: Colors.transparent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.nunito(
            color: const Color(0xFF45536D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF45536D)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF5388),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0xFFEF5388).withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5388), width: 2),
          ),
          hintStyle: GoogleFonts.nunito(color: const Color(0xFF45536D).withOpacity(0.4)),
        ),
      ),
      home: const OTP24SplashScreen(),
    );
  }
}
