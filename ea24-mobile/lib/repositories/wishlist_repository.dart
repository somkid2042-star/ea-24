import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/middlewares/banned_user.dart';
import 'package:ea24_mobile/repositories/api-request.dart';
import 'package:ea24_mobile/screens/wishlist/models/wishlist_check_response.dart';
import 'package:ea24_mobile/screens/wishlist/models/wishlist_delete_response.dart';
import 'package:ea24_mobile/screens/wishlist/models/wishlist_response.dart';

import '../helpers/main_helpers.dart';

class WishListRepository {
  Future<dynamic> getUserWishlist() async {
    String url = ("${AppConfig.BASE_URL}/wishlists");
    Map<String, String> header = commonHeader;

    header.addAll(authHeader);
    header.addAll(currencyHeader);

    final response = await ApiRequest.get(
      url: url,
      headers: header,
      middleware: BannedUser(),
    );

    return wishlistResponseFromJson(response.body);
  }

  Future<dynamic> delete({int? wishlistId = 0}) async {
    String url = ("${AppConfig.BASE_URL}/wishlists/$wishlistId");
    final response = await ApiRequest.delete(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return wishlistDeleteResponseFromJson(response.body);
  }

  Future<dynamic> isProductInUserWishList({productSlug = ''}) async {
    String url = ("${AppConfig.BASE_URL}/wishlists-check-product/$productSlug");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return wishListCheckResponseFromJson(response.body);
  }

  Future<dynamic> add({productSlug = ''}) async {
    String url = ("${AppConfig.BASE_URL}/wishlists-add-product/$productSlug");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return wishListCheckResponseFromJson(response.body);
  }

  Future<dynamic> remove({productSlug = ''}) async {
    String url =
        ("${AppConfig.BASE_URL}/wishlists-remove-product/$productSlug");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );

    return wishListCheckResponseFromJson(response.body);
  }
}
