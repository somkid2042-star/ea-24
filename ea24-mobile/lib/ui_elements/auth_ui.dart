import 'package:ea24_mobile/custom/box_decorations.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:flutter/material.dart';

class AuthScreen {
  static Widget buildScreen(
    BuildContext context,
    String headerText,
    Widget child,
  ) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background container
            Container(
              height: DeviceInfo(context).height! / 3,
              width: DeviceInfo(context).width,
              color: MyTheme.accent_color,
              alignment: Alignment.topRight,
              child: Image.asset("assets/background_1.png"),
            ),
            // CustomScrollView
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: MyTheme.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/login_registration_form_logo.png',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                      child: Text(
                        headerText,
                        style: TextStyle(
                          color: MyTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecorations.buildBoxDecoration_1(
                          radius: 16,
                        ),
                        child: child,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            // Cross Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
