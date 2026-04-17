import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/language_list_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';

class LanguageRepository {
  Future<LanguageListResponse> getLanguageList() async {
    String url = ("${AppConfig.BASE_URL}/languages");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return languageListResponseFromJson(response.body);
  }
}
