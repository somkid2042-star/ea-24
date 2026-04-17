import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/conversation_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/message_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/banned_user.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

import '../data_model/conversation_create_response.dart';

class ChatRepository {
  Future<dynamic> getConversationResponse({page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/chat/conversations?page=$page");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return conversationResponseFromJson(response.body);
  }

  Future<dynamic> getMessageResponse({
    required conversationId,
    page = 1,
  }) async {
    String url =
        ("${AppConfig.BASE_URL}/chat/messages/$conversationId?page=$page");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return messageResponseFromJson(response.body);
  }

  Future<dynamic> getInserMessageResponse({
    required conversationId,
    required String message,
  }) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "conversation_id": "$conversationId",
      "message": message,
    });

    String url = ("${AppConfig.BASE_URL}/chat/insert-message");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return messageResponseFromJson(response.body);
  }

  Future<dynamic> getNewMessageResponse({
    required conversationId,
    required lastMessageId,
  }) async {
    String url =
        ("${AppConfig.BASE_URL}/chat/get-new-messages/$conversationId/$lastMessageId");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return messageResponseFromJson(response.body);
  }

  Future<dynamic> getCreateConversationResponse({
    required productId,
    required String title,
    required String message,
  }) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "product_id": "$productId",
      "title": title,
      "message": message,
    });
    String url = ("${AppConfig.BASE_URL}/chat/create-conversation");

    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return conversationCreateResponseFromJson(response.body);
  }
}
