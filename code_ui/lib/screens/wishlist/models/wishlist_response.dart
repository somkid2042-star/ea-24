import 'dart:convert';

WishlistResponse wishlistResponseFromJson(String str) =>
    WishlistResponse.fromJson(json.decode(str));

String wishlistResponseToJson(WishlistResponse data) =>
    json.encode(data.toJson());

class WishlistResponse {
  WishlistResponse({this.wishlistItems, this.success, this.status});

  List<WishlistItem>? wishlistItems;
  bool? success;
  int? status;

  factory WishlistResponse.fromJson(Map<String, dynamic> json) =>
      WishlistResponse(
        wishlistItems: List<WishlistItem>.from(
          json["data"].map((x) => WishlistItem.fromJson(x)),
        ),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(wishlistItems!.map((x) => x.toJson())),
    "success": success,
    "status": status,
  };
}

class WishlistItem {
  WishlistItem({this.id, this.product});

  int? id;
  Product? product;

  factory WishlistItem.fromJson(Map<String, dynamic> json) =>
      WishlistItem(id: json["id"], product: Product.fromJson(json["product"]));

  Map<String, dynamic> toJson() => {"id": id, "product": product!.toJson()};
}

class Product {
  Product({
    this.id,
    this.name,
    this.thumbnailImage,
    this.basePrice,
    this.rating,
    this.slug,
  });

  int? id;
  String? name;
  String? thumbnailImage;
  String? basePrice;
  int? rating;
  String? slug;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json["id"],
    name: json["name"],
    thumbnailImage: json["thumbnail_image"],
    basePrice: json["base_price"],
    rating: json["rating"],
    slug: json["slug"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "thumbnail_image": thumbnailImage,
    "base_price": basePrice,
    "rating": rating,
    "slug": slug,
  };
}
