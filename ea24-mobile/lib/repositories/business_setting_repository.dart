import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/business_setting_response.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class BusinessSettingRepository {
  Future<BusinessSettingListResponse> getBusinessSettingList() async {
    String url = ("${AppConfig.BASE_URL}/business-settings");
    var businessSettings = [
      "facebook_login",
      "google_login",
      "twitter_login",
      "pickup_point",
      "wallet_system",
      "email_verification",
      "conversation_system",
      "shipping_type",
      "classified_product",
      "google_recaptcha",
      "vendor_system_activation",
      "guest_checkout_activation",
      "last_viewed_product_activation",
      "notification_show_type",
      "has_state",
      "recaptcha_customer_register",
      "recaptcha_customer_login",
      "recaptcha_forgot_password",
    ];
    businessSettings.join(',');

    var response = await ApiRequest.get(url: url);

    return businessSettingListResponseFromJson(response.body);
  }
}
