// To parse this JSON data, do
//
//     final shippingCostResponse = shippingCostResponseFromJson(jsonString);

import 'dart:convert';

ShippingCostResponse shippingCostResponseFromJson(String str) =>
    ShippingCostResponse.fromJson(json.decode(str));

String shippingCostResponseToJson(ShippingCostResponse data) =>
    json.encode(data.toJson());

class ShippingCostResponse {
  ShippingCostResponse({
    this.result,
    this.shippingType,
    this.value,
    this.valueString,
  });

  bool? result;
  String? shippingType;
  dynamic value;
  String? valueString;

  factory ShippingCostResponse.fromJson(Map<String, dynamic> json) =>
      ShippingCostResponse(
        result: json["result"],
        shippingType: json["shipping_type"],
        value: (json["value"] as num?)?.toDouble() ?? 0.0,
        valueString: json["value_string"],
      );


  Map<String, dynamic> toJson() => {
    "result": result,
    "shipping_type": shippingType,
    "value": value,
    "value_string": valueString,
  };
}
