import 'dart:convert';

ProfileCountersResponse profileCountersResponseFromJson(String str) =>
    ProfileCountersResponse.fromJson(json.decode(str));

String profileCountersResponseToJson(ProfileCountersResponse data) =>
    json.encode(data.toJson());

class ProfileCountersResponse {
  ProfileCountersResponse({
    this.cartItemCount,
    this.wishlistItemCount,
    this.orderCount,
  });

  int? cartItemCount;
  int? wishlistItemCount;
  int? orderCount;

  factory ProfileCountersResponse.fromJson(Map<String, dynamic> json) =>
      ProfileCountersResponse(
        cartItemCount: json["cart_item_count"],
        wishlistItemCount: json["wishlist_item_count"],
        orderCount: json["order_count"],
      );

  Map<String, dynamic> toJson() => {
    "cart_item_count": cartItemCount,
    "wishlist_item_count": wishlistItemCount,
    "order_count": orderCount,
  };
}
