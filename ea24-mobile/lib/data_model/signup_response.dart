// To parse this JSON data, do
//
//     final signupResponse = signupResponseFromJson(jsonString);

import 'dart:convert';

SignupResponse signupResponseFromJson(String str) =>
    SignupResponse.fromJson(json.decode(str));

String signupResponseToJson(SignupResponse data) => json.encode(data.toJson());

class SignupResponse {
  SignupResponse({this.result, this.message, this.userId});

  bool? result;
  dynamic message;
  int? userId;

  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
    result: json["result"],
    message: json["message"],
    userId: json["user_id"],
  );

  Map<String, dynamic> toJson() => {
    "result": result,
    "message": message,
    "user_id": userId,
  };
}
