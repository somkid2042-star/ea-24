import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/search_suggestion_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class SearchRepository {
  Future<List<SearchSuggestionResponse>> getSearchSuggestionListResponse({
    queryKey = "",
    type = "product",
  }) async {
    String url =
        ("${AppConfig.BASE_URL}/get-search-suggestions?query_key=$queryKey&type=$type");
    final response = await ApiRequest.get(
      url: url,
      headers: {"App-Language": app_language.$!},
    );
    return searchSuggestionResponseFromJson(response.body);
  }
}
