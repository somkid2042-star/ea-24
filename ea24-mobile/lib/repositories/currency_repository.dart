import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/currency_response.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class CurrencyRepository {
  Future<CurrencyResponse> getListResponse() async {
    String url = ('${AppConfig.BASE_URL}/currencies');

    final response = await ApiRequest.get(url: url);
    return currencyResponseFromJson(response.body);
  }
}
