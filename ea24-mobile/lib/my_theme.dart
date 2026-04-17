// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

ThemeData lightMode = ThemeData();

class MyTheme {
  /*configurable colors stars*/
  static Color mainColor = Color(0xffF2F1F6);
  static const Color accent_color = Color(0xff0066CC);
  static const Color accent_color_shadow = Color.fromRGBO(
    229,
    65,
    28,
    .40,
  ); // this color is a dropshadow of
  static Color soft_accent_color = Color.fromRGBO(254, 234, 209, 1);
  static Color splash_screen_color = Color(0xff0066CC);
  static Color price_color = Colors.black;
  static Color blackColour=Colors.black;

  /*configurable colors ends*/
  /*If you are not a developer, do not change the bottom colors*/
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  static Color noColor = Color.fromRGBO(255, 255, 255, 0);
  static Color light_grey = Color.fromRGBO(239, 239, 239, 1);
  static Color dark_grey = Color.fromRGBO(107, 115, 119, 1);
  static Color medium_grey = Color.fromRGBO(167, 175, 179, 1);
  static Color blue_grey = Color.fromRGBO(168, 175, 179, 1);
  static Color medium_grey_50 = Color.fromRGBO(167, 175, 179, .5);
  static const Color grey_153 = Color.fromRGBO(153, 153, 153, 1);
  static Color dark_font_grey = Color.fromRGBO(62, 68, 71, 1);
  static const Color font_grey = Color.fromRGBO(107, 115, 119, 1);
  static const Color textfield_grey = Color.fromRGBO(209, 209, 209, 1);
  static const Color font_grey_Light = Color(0xff6B7377);
  static Color golden = Color.fromRGBO(255, 168, 0, 1);
  static Color amber = Color.fromRGBO(254, 234, 209, 1);
  static Color amber_medium = Color.fromRGBO(254, 240, 215, 1);
  static Color golden_shadow = Color(0xff0066CC).withValues(alpha: .15);
  static Color black_shadow = Colors.black.withValues(alpha: .15);
  static Color green = Colors.green;
  static Color? green_light = Colors.green[200];
  static Color shimmer_base = Colors.grey.shade50;
  static Color shimmer_highlighted = Colors.grey.shade200;
  //testing shimmer
  /*static Color shimmer_base = Colors.redAccent;
  static Color shimmer_highlighted = Colors.yellow;*/

  // gradient color for coupons
  static const Color gigas = Color.fromRGBO(95, 74, 139, 1);
  static const Color polo_blue = Color.fromRGBO(152, 179, 209, 1);
  static const Color blue_chill = Color.fromRGBO(71, 148, 147, 1);
  static const Color cruise = Color.fromRGBO(124, 196, 195, 1);
  static const Color brick_red = Color.fromRGBO(191, 25, 49, 1);
  static const Color cinnabar = Color.fromRGBO(226, 88, 62, 1);

  static TextTheme textTheme1 = TextTheme(
    bodyLarge: TextStyle(fontFamily: "PublicSansSerif", fontSize: 14),
    bodyMedium: TextStyle(fontFamily: "PublicSansSerif", fontSize: 12),
  );
  static TextTheme textTheme2 = TextTheme(
    bodyLarge: TextStyle(fontFamily: "Inter", fontSize: 14),
    bodyMedium: TextStyle(fontFamily: "Inter", fontSize: 12),
  );

  static LinearGradient buildLinearGradient3() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.polo_blue, MyTheme.gigas],
    );
  }

  static LinearGradient buildLinearGradient2() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.cruise, MyTheme.blue_chill],
    );
  }

  static LinearGradient buildLinearGradient1() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.cinnabar, MyTheme.brick_red],
    );
  }

  static BoxShadow commonShadow() {
    return BoxShadow(
      color: Colors.black.withValues(alpha: .08),
      blurRadius: 20,
      spreadRadius: 0.0,
      offset: Offset(0.0, 10.0),
    );
  }

  static TextStyle homeText_heding() {
    return TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle priceText({required Color color}) {
    return TextStyle(
      color: color,
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
    );
  }
  static TextStyle productNameStyle() {
    return TextStyle(
      color: MyTheme.font_grey,
      fontSize: 12.sp,
      height: 1.2,
      fontWeight: FontWeight.w400,
    );
  }
}
