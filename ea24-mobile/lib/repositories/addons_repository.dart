import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/addons_response.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class AddonsRepository {
  Future<List<AddonsListResponse>> getAddonsListResponse() async {

    String url = ('${AppConfig.BASE_URL}/addon-list');
    final response = await ApiRequest.get(url: url);

    return addonsListResponseFromJson(response.body);
  }
}

