// To parse this JSON data, do
//
//     final conversationCreateResponse = conversationCreateResponseFromJson(jsonString);

import 'dart:convert';

ConversationCreateResponse conversationCreateResponseFromJson(String str) =>
    ConversationCreateResponse.fromJson(json.decode(str));

String conversationCreateResponseToJson(ConversationCreateResponse data) =>
    json.encode(data.toJson());

class ConversationCreateResponse {
  ConversationCreateResponse({
    this.result,
    this.conversationId,
    this.shopName,
    this.title,
    this.shopLogo,
    this.message,
  });

  bool? result;
  int? conversationId;
  String? shopName;
  String? title;
  String? shopLogo;
  String? message;

  factory ConversationCreateResponse.fromJson(Map<String, dynamic> json) =>
      ConversationCreateResponse(
        result: json["result"],
        conversationId: json["conversation_id"],
        title: json["title"],
        shopName: json["shop_name"],
        shopLogo: json["shop_logo"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "result": result,
    "conversation_id": conversationId,
    "shop_name": shopName,
    "title": title,
    "shop_logo": shopLogo,
    "message": message,
  };
}
