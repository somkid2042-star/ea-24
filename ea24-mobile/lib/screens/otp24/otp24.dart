/// OTP24 Mobile Module — mirrors the OTP24HR browser extension
/// 
/// This module provides a complete mobile experience for OTP24HR HUB:
/// - [OTP24SplashScreen] — Premium animated splash with spinning rings
/// - [OTP24HomeScreen]   — Dashboard with device sync, status, and app grid
/// - [OTP24AppViewerScreen] — Node discovery + cookie fetching + browser launch
/// - [OTP24Service]      — All API communication with EA-Server
///
/// Usage:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const OTP24SplashScreen(),
/// ));
/// ```
library otp24;

export 'otp24_splash_screen.dart';
export 'otp24_home_screen.dart';
export 'otp24_app_viewer_screen.dart';
export 'otp24_service.dart';
