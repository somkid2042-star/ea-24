import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/repositories/api-request.dart';
import 'package:ea24_mobile/data_model/language_list_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';

class LanguageRepository {
  Future<LanguageListResponse> getLanguageList() async {
    String url = ("${AppConfig.BASE_URL}/languages");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return languageListResponseFromJson(response.body);
  }
}
