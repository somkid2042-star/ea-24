import 'dart:convert';

import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/offline_wallet_recharge_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/middlewares/banned_user.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class OfflineWalletRechargeRepository {
  Future<dynamic> getOfflineWalletRechargeResponse({
    required String amount,
    required String name,
    required String trxId,
    required int? photo,
  }) async {
    var postBody = jsonEncode({
      "amount": amount,
      "payment_option": "Offline Payment",
      "trx_id": trxId,
      "photo": "$photo",
    });
    String url = ("${AppConfig.BASE_URL}/wallet/offline-recharge");
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

    return offlineWalletRechargeResponseFromJson(response.body);
  }
}
