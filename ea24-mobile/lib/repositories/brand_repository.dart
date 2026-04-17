import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/all_brands_response.dart';
import 'package:ea24_mobile/data_model/brand_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class BrandRepository {
  Future<BrandResponse> getFilterPageBrands() async {
    String url = ("${AppConfig.BASE_URL}/filter/brands");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return brandResponseFromJson(response.body);
  }

  Future<BrandResponse> getBrands({name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/brands" "?page=$page&name=$name");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return brandResponseFromJson(response.body);
  }

  Future<AllBrandsResponse> getAllBrands() async {
    String url = ("${AppConfig.BASE_URL}/all-brands");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return allBrandsResponseFromJson(response.body);
  }
}
