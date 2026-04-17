import 'package:ea24_mobile/my_theme.dart';
import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration buildInputDecoration_1({hintText = ""}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: MyTheme.white,
      hintStyle: TextStyle(fontSize: 12.0, color: Color(0xffA8AFB3)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.accent_color, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.0),
    );
  }

  static InputDecoration buildInputDecorationPhone({hintText = ""}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.textfield_grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.textfield_grey, width: 0.5),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.0),
          bottomRight: Radius.circular(6.0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.accent_color, width: 0.5),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.0),
          bottomRight: Radius.circular(6.0),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
