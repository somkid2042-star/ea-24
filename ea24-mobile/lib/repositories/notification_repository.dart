import 'dart:convert';

import 'package:ea24_mobile/data_model/common_response.dart';

import '../app_config.dart';
import '../helpers/main_helpers.dart';
import '../middlewares/banned_user.dart';
import '../screens/notification/models/all_notification_list_response.dart';
import '../screens/notification/models/unread_notification_list_response.dart';
import 'api-request.dart';

class NotificationRepository {
  Future<AllNotificationListResponse> getAllNotification() async {
    String url = ("${AppConfig.BASE_URL}/all-notification");
    Map<String, String> header = commonHeader;
    header.addAll(authHeader);
    final response = await ApiRequest.get(
      url: url,
      headers: header,
      middleware: BannedUser(),
    );

    return allNotificationListResponseFromJson(response.body);
  }

  Future<UnreadNotificationListResponse> getUnreadNotification() async {
    String url = ("${AppConfig.BASE_URL}/unread-notifications");
    Map<String, String> header = commonHeader;
    header.addAll(authHeader);
    final response = await ApiRequest.get(
      url: url,
      headers: header,
      middleware: BannedUser(),
    );
    return unreadNotificationListResponseFromJson(response.body);
  }

  Future<CommonResponse> notificationBulkDelete(notificationIds) async {
    var postBody = jsonEncode({"notification_ids": "$notificationIds"});

    String url = ("${AppConfig.BASE_URL}/notifications/bulk-delete");
    Map<String, String> header = commonHeader;
    header.addAll(authHeader);
    final response = await ApiRequest.post(
      url: url,
      headers: header,
      middleware: BannedUser(),
      body: postBody,
    );
    return commonResponseFromJson(response.body);
  }
}
