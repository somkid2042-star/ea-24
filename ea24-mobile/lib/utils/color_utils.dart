import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifier/theme_provider.dart';
import 'app_style.dart';

class ColorUtils {
  static bool getMode(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  }

  static Color getBackGround(BuildContext context) {
    return getMode(context) ? Styles.textColorDark : Styles.primaryColor;
  }

  static Color getPrimaryText(BuildContext context) {
    return getMode(context) ? Styles.primaryColor : Styles.textColorDark;
  }

  static Color getSecondText(BuildContext context) {
    return getMode(context)
        ? Styles.textColorDarkLight
        : Styles.textColorLight;
  }

  static Color getLineColor(BuildContext context) {
    return getMode(context) ? Styles.lineColorDark : Styles.lineColor;
  }

  static Color getBottomLineColor(BuildContext context) {
    return getMode(context)
        ? Styles.bottomLineColorDark
        : Styles.bottomLineColor;
  }

  static Color getCardColor(BuildContext context) {
    return getMode(context) ? Styles.cardDark : Styles.cardLight;
  }

  static Color getShimmerBase(BuildContext context) {
    return getMode(context) ? Styles.shimmerBaseDark : Styles.shimmerBaseLight;
  }

  static Color getShimmerHigh(BuildContext context) {
    return getMode(context) ? Styles.shimmerHighDark : Styles.shimmerHighLight;
  }

  static Color getBlackWhite(BuildContext context) {
    return getMode(context) ? Colors.white : Colors.black;
  }

  static Color getSplashName(BuildContext context) {
    return getMode(context) ? Colors.white : Styles.splashNameBlue;
  }

  static Color getTrackColor(BuildContext context) {
    return getMode(context) ? Styles.trackTintDark : Styles.trackTint;
  }

  static Color getThumbColor(BuildContext context) {
    return getMode(context) ? Styles.thumbTintDark : Styles.thumbTint;
  }

  static Color getTrackColorActive(BuildContext context) {
    return getMode(context)
        ? Styles.trackTintActiveDark
        : Styles.trackTintActive;
  }

  static Color getThumbColorActive(BuildContext context) {
    return getMode(context)
        ? Styles.thumbTintActiveDark
        : Styles.thumbTintActive;
  }
}
