import 'dart:async';
import 'package:flutter/material.dart';
import 'otp24_home_screen.dart';

/// OTP24 Splash Screen — premium loading animation
class OTP24SplashScreen extends StatefulWidget {
  const OTP24SplashScreen({super.key});

  @override
  State<OTP24SplashScreen> createState() => _OTP24SplashScreenState();
}

class _OTP24SplashScreenState extends State<OTP24SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _ringRotation;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Logo scale — simple tween with elasticOut (no TweenSequence)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Ring spin
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _ringRotation = Tween<double>(begin: 0, end: 6.28).animate(_ringController);

    // Text fade in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Start sequence
    _logoController.forward();
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    // Navigate after delay
    Timer(const Duration(milliseconds: 2200), () {
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
    _ringController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo with ring
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer spinning ring
                  AnimatedBuilder(
                    animation: _ringRotation,
                    builder: (_, child) => Transform.rotate(
                      angle: _ringRotation.value,
                      child: child,
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                          width: 2,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFFF5722).withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner spinning ring
                  AnimatedBuilder(
                    animation: _ringRotation,
                    builder: (_, child) => Transform.rotate(
                      angle: -_ringRotation.value * 0.7,
                      child: child,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Title
            FadeTransition(
              opacity: _textOpacity,
              child: Column(
                children: [
                  const Text(
                    'OTP24HR HUB',
                    style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SYSTEM SECURE PROCESSING...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
