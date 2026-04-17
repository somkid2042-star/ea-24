// To parse this JSON data, do
//
//     final simpleImageUploadResponse = simpleImageUploadResponseFromJson(jsonString);

import 'dart:convert';

SimpleImageUploadResponse simpleImageUploadResponseFromJson(String str) =>
    SimpleImageUploadResponse.fromJson(json.decode(str));

String simpleImageUploadResponseToJson(SimpleImageUploadResponse data) =>
    json.encode(data.toJson());

class SimpleImageUploadResponse {
  SimpleImageUploadResponse({
    this.result,
    this.message,
    this.path,
    this.uploadId,
  });

  bool? result;
  String? message;
  String? path;
  int? uploadId;

  factory SimpleImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      SimpleImageUploadResponse(
        result: json["result"],
        message: json["message"],
        path: json["path"],
        uploadId: json["upload_id"],
      );

  Map<String, dynamic> toJson() => {
    "result": result,
    "message": message,
    "path": path,
    "upload_id": uploadId,
  };
}
