import 'package:active_ecommerce_cms_demo_app/custom/only_number_formatter.dart';
import 'package:flutter/material.dart';

class QuantityInputField {
  static TextField show(TextEditingController controller,
      {required VoidCallback onSubmitted, bool isDisable = false}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      readOnly: isDisable,
      keyboardType: TextInputType.number,
      inputFormatters: [OnlyNumberFormatter()],
      onSubmitted: (str) {
        onSubmitted();
      },
      decoration: InputDecoration.collapsed(hintText: "0"),
    );
  }
}
