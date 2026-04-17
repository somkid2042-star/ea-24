import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/pickup_points_response.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class PickupPointRepository {
  Future<PickupPointListResponse> getPickupPointListResponse() async {
    String url = ('${AppConfig.BASE_URL}/pickup-list');

    final response = await ApiRequest.get(url: url);

    return pickupPointListResponseFromJson(response.body);
  }
}
