import 'package:flutter/material.dart';

class BoxDecorations {
  static BoxDecoration buildBoxDecoration_1({double radius = 6.0}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white,
    );
  }

  static BoxDecoration buildBoxDecorationWithShadow({double radius = 6.0}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 20,
          spreadRadius: 0.0,
          offset: Offset(0.0, 10.0),
        ),
      ],
    );
  }

  static BoxDecoration buildCartCircularButtonDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16.0),
      color: Color.fromRGBO(229, 241, 248, 1),
    );
  }

  static BoxDecoration buildCircularButtonDecoration_1() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(36.0),
      color: Colors.white.withValues(alpha: 0.80),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 0.0,
          offset: Offset(0.0, 10.0),
        ),
      ],
    );
  }

  static BoxDecoration buildCircularButtonDecorationForProductDetails() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.80),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset(0.0, 10.0),
        ),
      ],
    );
  }
}
