import 'dart:convert';

import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/offline_payment_submit_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/middlewares/banned_user.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class OfflinePaymentRepository {
  Future<dynamic> getOfflinePaymentSubmitResponse({
    required int? orderId,
    required String amount,
    required String name,
    required String trxId,
    required int? photo,
  }) async {
    var postBody = jsonEncode({
      "order_id": "$orderId",
      "amount": amount,
      "name": name,
      "trx_id": trxId,
      "photo": "$photo",
    });

    String url = ("${AppConfig.BASE_URL}/offline/payment/submit");

    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
        "Accept": "application/json",
        "System-Key": AppConfig.system_key,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return offlinePaymentSubmitResponseFromJson(response.body);
  }
}
