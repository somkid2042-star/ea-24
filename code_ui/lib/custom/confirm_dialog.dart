import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:flutter/material.dart';

class ConfirmDialog {
  static show(
    BuildContext context, {
    String? title,
    required String message,
    String? yesText,
    String? noText,
    required VoidCallback pressYes,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyTheme.white,
          title: Text(
            "Please ensure us.",
            style: TextStyle(
              fontSize: 16,
              color: MyTheme.font_grey,
              fontWeight: .bold,
            ),
          ),
          content: Row(
            children: [
              SizedBox(
                width: DeviceInfo(context).width! * 0.6,
                child: Text(
                  message,
                  style: TextStyle(fontSize: 14, color: MyTheme.font_grey),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: MyTheme.grey_153),
                      ),
                      child: Center(
                        child: Text(
                          noText ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: MyTheme.font_grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      pressYes();
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          "Yes",
                          style: TextStyle(fontSize: 14, color: MyTheme.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
