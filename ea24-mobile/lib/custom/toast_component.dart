import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../my_theme.dart';

class ToastComponent {
  static showDialog(String msg, {duration = 0, gravity = 0}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Color.fromRGBO(239, 239, 239, .9),
      textColor: MyTheme.font_grey,
    );
  }
}
