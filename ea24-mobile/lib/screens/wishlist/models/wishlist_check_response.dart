import 'dart:convert';

WishListCheckResponse wishListCheckResponseFromJson(String str) =>
    WishListCheckResponse.fromJson(json.decode(str));

String wishListCheckResponseToJson(WishListCheckResponse data) =>
    json.encode(data.toJson());

class WishListCheckResponse {
  WishListCheckResponse({
    this.message,
    this.isInWishlist,
    this.productId,
    this.wishlistId,
  });

  String? message;
  bool? isInWishlist;
  int? productId;
  int? wishlistId;

  factory WishListCheckResponse.fromJson(Map<String, dynamic> json) =>
      WishListCheckResponse(
        message: json["message"],
        isInWishlist: json["is_in_wishlist"],
        productId: json["product_id"],
        wishlistId: json["wishlist_id"],
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "is_in_wishlist": isInWishlist,
    "product_id": productId,
    "wishlist_id": wishlistId,
  };
}
