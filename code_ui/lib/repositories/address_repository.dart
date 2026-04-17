import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_add_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_delete_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_make_default_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_update_in_cart_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_update_location_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/address_update_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/city_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/country_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/shipping_cost_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/state_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/banned_user.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class AddressRepository {
  Future<dynamic> getAddressList() async {
    String url = ("${AppConfig.BASE_URL}/user/shipping/address");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );
    return addressResponseFromJson(response.body);
  }

  Future<CityResponse> getCityListByCountry({
    int countryId = 0,
    name = "",
  }) async {
    String url =
        ("${AppConfig.BASE_URL}/cities-by-country/$countryId?name=$name");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
        "System-key": AppConfig.system_key,
      },
    );
    return cityResponseFromJson(response.body);
  }

  Future<dynamic> getHomeDeliveryAddress() async {
    String url = ("${AppConfig.BASE_URL}/get-home-delivery-address");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );
    return addressResponseFromJson(response.body);
  }

  Future<dynamic> getAddressAddResponse({
    required String address,
    required int? countryId,
    required int? stateId,
    required int? cityId,
    required int? areaId,
    required String postalCode,
    required String phone,
  }) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "address": address,
      "country_id": "$countryId",
      "state_id": "$stateId",
      "city_id": "$cityId",
      "area_id": "$areaId",
      "postal_code": postalCode,
      "phone": phone,
    });

    String url = ("${AppConfig.BASE_URL}/user/shipping/create");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return addressAddResponseFromJson(response.body);
  }

  Future<dynamic> getAddressUpdateResponse({
    required int id,
    required String address,
    required int? countryId,
    required int? stateId,
    required int? areaId,
    required int? cityId,
    required String postalCode,
    required String phone,
  }) async {
    Map<String, dynamic> postBodyMap = {
      "id": id,
      "user_id": "${user_id.$}",
      "address": address,
      "country_id": countryId ?? "",
      "area_id": areaId ?? "",
      "city_id": cityId ?? "",
      "postal_code": postalCode,
      "phone": phone,
    };

    if (stateId != null && stateId != 0) {
      postBodyMap["state_id"] = stateId;
    }
    var postBody = jsonEncode(postBodyMap);
    String url = ("${AppConfig.BASE_URL}/user/shipping/update");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return addressUpdateResponseFromJson(response.body);
  }

  Future<dynamic> getAddressUpdateLocationResponse(
    int? id,
    double? latitude,
    double? longitude,
  ) async {
    var postBody = jsonEncode({
      "id": "$id",
      "user_id": "${user_id.$}",
      "latitude": "$latitude",
      "longitude": "$longitude",
    });

    String url = ("${AppConfig.BASE_URL}/user/shipping/update-location");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return addressUpdateLocationResponseFromJson(response.body);
  }

  Future<dynamic> getAddressMakeDefaultResponse(int? id, {bool isDefaultShipping = false, bool isDefaultBilling = false}) async {
    Map<String, dynamic> requestBody = {"id": "$id"};

    if (isDefaultShipping) {
      requestBody["set_default"] = 1;
    }
    if (isDefaultBilling) {
      requestBody["set_billing"] = 1;
    }

    var postBody = jsonEncode(requestBody);

    String url = ("${AppConfig.BASE_URL}/user/shipping/make_default");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return addressMakeDefaultResponseFromJson(response.body);
  }

  Future<dynamic> getAddressDeleteResponse(int? id) async {
    String url = ("${AppConfig.BASE_URL}/user/shipping/delete/$id");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      middleware: BannedUser(),
    );

    return addressDeleteResponseFromJson(response.body);
  }

  Future<dynamic> getAriaListByCity({cityId = 0, name = ""}) async {
    String url = ("${AppConfig.BASE_URL}/areas-by-city/$cityId?name=$name");
    final response = await ApiRequest.get(url: url, middleware: BannedUser());
    return cityResponseFromJson(response.body);
  }

  Future<dynamic> getCityListByState({stateId = 0, name = ""}) async {
    String url = ("${AppConfig.BASE_URL}/cities-by-state/$stateId?name=$name");
    final response = await ApiRequest.get(url: url, middleware: BannedUser());
    return cityResponseFromJson(response.body);
  }

  Future<dynamic> getStateListByCountry({countryId = 0, name = ""}) async {
    String url =
        ("${AppConfig.BASE_URL}/states-by-country/$countryId?name=$name");
    final response = await ApiRequest.get(url: url, middleware: BannedUser());
    return myStateResponseFromJson(response.body);
  }

  Future<dynamic> getCountryList({name = ""}) async {
    String url = ("${AppConfig.BASE_URL}/countries?name=$name");
    final response = await ApiRequest.get(url: url, middleware: BannedUser());
    return countryResponseFromJson(response.body);
  }

  Future<dynamic> getShippingCostResponse({shippingType = ""}) async {
    String postBody;

    String url = ("${AppConfig.BASE_URL}/shipping_cost");
    if (guest_checkout_status.$ && !is_logged_in.$) {
      postBody = jsonEncode({
        "temp_user_id": temp_user_id.$,
        "seller_list": shippingType,
      });
    } else {
      postBody = jsonEncode({
        "user_id": user_id.$,
        "seller_list": shippingType,
      });
    }
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return shippingCostResponseFromJson(response.body);
  }

  Future<dynamic> getAddressUpdateInCartResponse({
    int? addressId = 0,
    int? billingAddressId = 0,
  }) async {
    var postBody = jsonEncode({
      "address_id": "$addressId",
      "billing_address_id": "$billingAddressId",
      "user_id": "${user_id.$}",
    });

    String url = ("${AppConfig.BASE_URL}/update-address-in-cart");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );
    return addressUpdateInCartResponseFromJson(response.body);
  }

  Future<dynamic> getShippingTypeUpdateInCartResponse({
    required int shippingId,
    shippingType = "home_delivery",
  }) async {
    var postBody = jsonEncode({
      "shipping_id": "$shippingId",
      "shipping_type": "$shippingType",
    });

    String url = ("${AppConfig.BASE_URL}/update-shipping-type-in-cart");

    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
      middleware: BannedUser(),
    );

    return addressUpdateInCartResponseFromJson(response.body);
  }
}
