// To parse this JSON data, do
//
//     final paymentTypeResponse = paymentTypeResponseFromJson(jsonString);

import 'dart:convert';

List<PaymentTypeResponse> paymentTypeResponseFromJson(String str) =>
    List<PaymentTypeResponse>.from(
      json.decode(str).map((x) => PaymentTypeResponse.fromJson(x)),
    );

String paymentTypeResponseToJson(List<PaymentTypeResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PaymentTypeResponse {
  PaymentTypeResponse({
    this.paymentType,
    this.paymentTypeKey,
    this.image,
    this.name,
    this.title,
    this.offlinePaymentId,
    this.details,
  });

  String? paymentType;
  String? paymentTypeKey;
  String? image;
  String? name;
  String? title;
  int? offlinePaymentId;
  String? details;

  factory PaymentTypeResponse.fromJson(Map<String, dynamic> json) =>
      PaymentTypeResponse(
        paymentType: json["payment_type"],
        paymentTypeKey: json["payment_type_key"],
        image: json["image"],
        name: json["name"],
        title: json["title"],
        offlinePaymentId: json["offline_payment_id"],
        details: json["details"],
      );

  Map<String, dynamic> toJson() => {
    "payment_type": paymentType,
    "payment_type_key": paymentTypeKey,
    "image": image,
    "name": name,
    "title": title,
    "offline_payment_id": offlinePaymentId,
    "details": details,
  };
}
