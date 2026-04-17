import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/data_model/category_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/repositories/api-request.dart';

class CategoryRepository {
  Future<CategoryResponse> getCategories({parentId = 0}) async {
    String url = ("${AppConfig.BASE_URL}/categories?parent_id=$parentId");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFeturedCategories() async {
    String url = ("${AppConfig.BASE_URL}/categories/featured");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );

    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getCategoryInfo(slug) async {
    String url = ("${AppConfig.BASE_URL}/category/info/$slug");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getTopCategories() async {
    String url = ("${AppConfig.BASE_URL}/categories/top");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFilterPageCategories() async {
    String url = ("${AppConfig.BASE_URL}/filter/categories");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );
    return categoryResponseFromJson(response.body);
  }
}
