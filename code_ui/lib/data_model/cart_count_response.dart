// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

CartCountResponse cartCountResponseFromJson(String str) =>
    CartCountResponse.fromJson(json.decode(str));

String cartCountResponseToJson(CartCountResponse data) =>
    json.encode(data.toJson());

class CartCountResponse {
  CartCountResponse({this.count, this.status});

  var count;
  bool? status;

  factory CartCountResponse.fromJson(Map<String, dynamic> json) =>
      CartCountResponse(count: json["count"], status: json["status"]);

  Map<String, dynamic> toJson() => {"count": count, "status": status};
}
