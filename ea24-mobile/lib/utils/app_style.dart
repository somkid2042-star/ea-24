import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color primary = const Color(0xFFFBFBFD);
Color primaryDark = const Color(0xFF0D1117);

class Styles {
  // Krungthai Blue Theme
  static Color primaryColor = const Color(0xff1BA0E1); // Krungthai Blue
  static Color primaryColorDark = const Color(0xff8EDDFB); 
  static Color textColorDark = const Color(0xff1D1D1D); // scaffoldColorDark
  static Color textColorLight = const Color(0xff8A8A8A); // textColor
  static Color textColorDarkLight = const Color(0xff8A8A8A);
  static Color bgColor = const Color(0xffFAFAFA); // BackgroundColorImageColor
  static Color lineColor = const Color(0xffEDEDED); // GreyLightColor 
  static Color lineColorDark = const Color(0x3DFFFFFF); // Colors.white24
  static Color bottomLineColor = const Color(0xffEDEDED);
  static Color bottomLineColorDark = const Color(0x3DFFFFFF);
  static Color viewLineColor = const Color(0xFFC5C6C7); // grayColor

  // Switch track/thumb colors
  static Color trackTint = const Color(0xFFCDCECE);
  static Color thumbTintDark = const Color(0xFFC5C6C8);
  static Color trackTintActive = const Color(0xFFC5C6C8);
  static Color thumbTintActive = const Color(0xff1BA0E1);
  static Color trackTintDark = const Color(0xFF2F323A);
  static Color thumbTint = const Color(0xFF363A48);
  static Color trackTintActiveDark = const Color(0xFF5C6172);
  static Color thumbTintActiveDark = const Color(0xff1BA0E1);

  // Trading accent colors (Kept from OTT)
  static Color accentCyan = const Color(0xff1BA0E1); // Primary instead of Cyan
  static Color accentGold = const Color(0xffF9AA00); // YellowColor
  static Color profitGreen = const Color(0xff199226); // GreenColor
  static Color lossRed = const Color(0xffF4462C); // RedColor
  static Color warningOrange = const Color(0xff1BA0E1);

  static Color splashNameBlue = const Color(0xff1BA0E1);

  static Color shimmerBaseLight = Colors.grey[300]!;
  static Color shimmerBaseDark = const Color(0xFF2F2F2F);
  static Color shimmerHighLight = Colors.grey[100]!;
  static Color shimmerHighDark = const Color(0xFF4A4A4A);

  static Color cardDark = const Color(0xFF2F2F2F); // cardDarkColor
  static Color cardLight = const Color(0xFFFAFAFA); // cardLightColor

  // Replaced default text style with Inter
  static TextStyle textStyle = GoogleFonts.inter(
      fontSize: 16, color: textColorDark, fontWeight: FontWeight.w500);
}
