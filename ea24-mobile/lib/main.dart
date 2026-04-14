import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notifier/navigation_notifier.dart';
import 'notifier/theme_provider.dart';
import 'notifier/trading_provider.dart';
import 'screens/splash_screen.dart';
import 'service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  try {
    await notificationService.ensureNotificationPermission();
  } catch(e) {
    debugPrint('Permission handler not supported on this platform: $e');
  }

  // Create providers
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final tradingProvider = TradingProvider();

  // Wire push notifications to trading events
  tradingProvider.onNotification = (title, body) {
    notificationService.showTradeNotification(title: title, body: body);
  };

  // Connect to server
  await tradingProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => NavigationNotifier()),
        ChangeNotifierProvider.value(value: tradingProvider),
      ],
      child: const EA24MobileApp(),
    ),
  );
}

class EA24MobileApp extends StatelessWidget {
  const EA24MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EA24 Mobile',
          theme: themeProvider.currentTheme
              ? MyThemes.darkTheme
              : MyThemes.lightTheme,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(0.9)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
