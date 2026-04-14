import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'color_utils.dart';

class AppLayout {
  static getSize() {
    WidgetsBinding? binding = WidgetsBinding.instance;
    return binding.window.physicalSize / binding.window.devicePixelRatio;
  }

  static getScreenHeight() {
    return getSize().height;
  }

  static getScreenWidth() {
    return getSize().width;
  }

  static getHeight(double pixels) {
    double x = getScreenHeight() / pixels;
    return getScreenHeight() / x;
  }

  static getWidth(double pixels) {
    double x = getScreenWidth() / pixels;
    return getScreenWidth() / x;
  }

  static screenPortrait() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static systemStatusColor(BuildContext context, {Color? colors}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: colors ?? ColorUtils.getBackGround(context),
      systemNavigationBarColor: ColorUtils.getBackGround(context),
    ));
  }
}
