import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp24_home_screen.dart';

/// OTP24 Splash Screen — clean Elite Quiz-inspired design
class OTP24SplashScreen extends StatefulWidget {
  const OTP24SplashScreen({super.key});

  @override
  State<OTP24SplashScreen> createState() => _OTP24SplashScreenState();
}

class _OTP24SplashScreenState extends State<OTP24SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleUp;
  late Animation<double> _logoScaleDown;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        if (_logoController.isCompleted) {
          _navigateToHome();
        }
      });

    _logoScaleUp = Tween<double>(begin: 0, end: 1.1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.ease),
      ),
    );
    _logoScaleDown = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1, curve: Curves.easeInOut),
      ),
    );

    _logoController.forward();
  }

  void _navigateToHome() {
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OTP24HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEF5388);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Logo — center bounce animation
            Align(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (_, __) => Transform.scale(
                  scale: _logoScaleUp.value - _logoScaleDown.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_fire_department,
                            color: primaryColor,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'OTP24HR',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'HUB',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
