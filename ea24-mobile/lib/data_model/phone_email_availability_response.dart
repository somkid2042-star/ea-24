// To parse this JSON data, do
//
//     final phoneEmailAvailabilityResponse = phoneEmailAvailabilityResponseFromJson(jsonString);

import 'dart:convert';

PhoneEmailAvailabilityResponse phoneEmailAvailabilityResponseFromJson(
  String str,
) => PhoneEmailAvailabilityResponse.fromJson(json.decode(str));

String phoneEmailAvailabilityResponseToJson(
  PhoneEmailAvailabilityResponse data,
) => json.encode(data.toJson());

class PhoneEmailAvailabilityResponse {
  PhoneEmailAvailabilityResponse({
    this.phoneAvailable,
    this.emailAvailable,
    this.phoneAvailableMessage,
    this.emailAvailableMessage,
  });

  bool? phoneAvailable;
  bool? emailAvailable;
  String? phoneAvailableMessage;
  String? emailAvailableMessage;

  factory PhoneEmailAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      PhoneEmailAvailabilityResponse(
        phoneAvailable: json["phone_available"],
        emailAvailable: json["email_available"],
        phoneAvailableMessage: json["phone_available_message"],
        emailAvailableMessage: json["email_available_message"],
      );

  Map<String, dynamic> toJson() => {
    "phone_available": phoneAvailable,
    "email_available": emailAvailable,
    "phone_available_message": phoneAvailableMessage,
    "email_available_message": emailAvailableMessage,
  };
}
