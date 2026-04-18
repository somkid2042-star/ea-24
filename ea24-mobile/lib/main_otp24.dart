import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/otp24/otp24.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0A0E1A),
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        primaryColor: const Color(0xFFFF5722),
        fontFamily: 'Inter',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFFFF9800),
          surface: const Color(0xFF141929),
        ),
      ),
      home: const OTP24SplashScreen(),
    );
  }
}
