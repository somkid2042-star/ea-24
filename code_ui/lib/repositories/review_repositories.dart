import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/data_model/review_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/review_submit_response.dart';

import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class ReviewRepository {
  Future<dynamic> getReviewResponse(int? productId, {page = 1}) async {
    String url =
        ("${AppConfig.BASE_URL}/reviews/product/$productId?page=$page");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );
    return reviewResponseFromJson(response.body);
  }

  Future<dynamic> getReviewSubmitResponse(
    int? productId,
    int rating,
    String comment,
    String? imageIds,
  ) async {
    var postBody = jsonEncode({
      "product_id": "$productId",
      "user_id": "${user_id.$}",
      "rating": "$rating",
      "comment": comment,
      "image_ids": "$imageIds",
    });

    String url = ("${AppConfig.BASE_URL}/reviews/submit");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );

    return reviewSubmitResponseFromJson(response.body);
  }
}
