// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

ProductDetailsResponse productDetailsResponseFromJson(String str) =>
    ProductDetailsResponse.fromJson(json.decode(str));

String productDetailsResponseToJson(ProductDetailsResponse data) =>
    json.encode(data.toJson());

class ProductDetailsResponse {
  ProductDetailsResponse({this.detailedProducts, this.success, this.status});

  List<DetailedProduct>? detailedProducts;
  bool? success;
  int? status;

  factory ProductDetailsResponse.fromJson(Map<String, dynamic> json) =>
      ProductDetailsResponse(
        detailedProducts: json["data"] == null
            ? []
            : List<DetailedProduct>.from(
                json["data"].map((x) => DetailedProduct.fromJson(x)),
              ),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": detailedProducts == null
        ? []
        : List<dynamic>.from(detailedProducts!.map((x) => x.toJson())),
    "success": success,
    "status": status,
  };
}

class DetailedProduct {
  DetailedProduct({
    this.id,
    this.name,
    this.addedBy,
    this.sellerId,
    this.shopId,
    this.shopSlug,
    this.shopName,
    this.shopLogo,
    this.photos,
    this.thumbnailImage,
    this.tags,
    this.priceHighLow,
    this.choiceOptions,
    this.colors,
    this.hasDiscount,
    this.discount,
    this.strokedPrice,
    this.mainPrice,
    this.calculablePrice,
    this.currencySymbol,
    this.currentStock,
    this.unit,
    this.rating,
    this.ratingCount,
    this.earnPoint,
    this.description,
    this.downloads,
    this.videoLink,
    this.videos,
    this.link,
    this.brand,
    this.wholesale,
    this.estShippingTime,
  });

  int? id;
  String? name;
  String? addedBy;
  int? sellerId;
  int? shopId;
  String? shopSlug;
  String? shopName;
  String? shopLogo;
  List<Photo>? photos;
  String? thumbnailImage;
  List<String>? tags;
  String? priceHighLow;
  List<ChoiceOption>? choiceOptions;
  List<dynamic>? colors;
  bool? hasDiscount;
  var discount;
  String? strokedPrice;
  String? mainPrice;
  var calculablePrice;
  String? currencySymbol;
  int? currentStock;
  String? unit;
  int? rating;
  int? ratingCount;
  int? earnPoint;
  String? description;
  String? downloads;
  List<dynamic>? videoLink;
  List<Video>? videos;
  String? link;
  Brand? brand;
  List<Wholesale>? wholesale;
  int? estShippingTime;

  factory DetailedProduct.fromJson(Map<String, dynamic> json) {
    List<dynamic> videoLinks = [];
    if (json["video_link"] != null) {
      if (json["video_link"] is List) {
        videoLinks = json["video_link"];
      } else if (json["video_link"] is String &&
          (json["video_link"] as String).isNotEmpty) {
        videoLinks = [json["video_link"]];
      }
    }

    return DetailedProduct(
      id: json["id"],
      name: json["name"],
      addedBy: json["added_by"],
      sellerId: json["seller_id"],
      shopId: json["shop_id"],
      shopSlug: json["shop_slug"],
      shopName: json["shop_name"],
      shopLogo: json["shop_logo"],
      estShippingTime: json["est_shipping_time"],
      photos: json["photos"] == null
          ? []
          : List<Photo>.from(json["photos"].map((x) => Photo.fromJson(x))),
      thumbnailImage: json["thumbnail_image"],
      tags: json["tags"] == null
          ? []
          : List<String>.from(json["tags"].map((x) => x)),
      priceHighLow: json["price_high_low"],
      choiceOptions: json["choice_options"] == null
          ? []
          : List<ChoiceOption>.from(
              json["choice_options"].map((x) => ChoiceOption.fromJson(x)),
            ),
      colors: json["colors"] == null
          ? []
          : List<String>.from(json["colors"].map((x) => x)),
      hasDiscount: json["has_discount"],
      discount: json["discount"],
      strokedPrice: json["stroked_price"],
      mainPrice: json["main_price"],
      calculablePrice: json["calculable_price"],
      currencySymbol: json["currency_symbol"],
      currentStock: json["current_stock"],
      unit: json["unit"],
      rating: json["rating"] == null ? 0 : json["rating"].toInt(),
      ratingCount: json["rating_count"],
      earnPoint: json["earn_point"] == null ? 0 : json["earn_point"].toInt(),
      description: json["description"] == null || json["description"] == ""
          ? "No Description is available"
          : json['description'],
      downloads: json["downloads"],

      videoLink: videoLinks,
      videos: json["videos"] == null
          ? []
          : List<Video>.from(json["videos"].map((x) => Video.fromJson(x))),
      link: json["link"],
      brand: json["brand"] == null ? null : Brand.fromJson(json["brand"]),
      wholesale: json["wholesale"] == null
          ? []
          : List<Wholesale>.from(
              json["wholesale"].map((x) => Wholesale.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "added_by": addedBy,
    "seller_id": sellerId,
    "shop_id": shopId,
    "est_shipping_time": estShippingTime,
    "shop_slug": shopSlug,
    "shop_name": shopName,
    "shop_logo": shopLogo,
    "photos": photos == null
        ? []
        : List<dynamic>.from(photos!.map((x) => x.toJson())),
    "thumbnail_image": thumbnailImage,
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
    "price_high_low": priceHighLow,
    "choice_options": choiceOptions == null
        ? []
        : List<dynamic>.from(choiceOptions!.map((x) => x.toJson())),
    "colors": colors == null ? [] : List<dynamic>.from(colors!.map((x) => x)),
    "discount": discount,
    "stroked_price": strokedPrice,
    "main_price": mainPrice,
    "calculable_price": calculablePrice,
    "currency_symbol": currencySymbol,
    "current_stock": currentStock,
    "unit": unit,
    "rating": rating,
    "rating_count": ratingCount,
    "earn_point": earnPoint,
    "description": description,
    "downloads": downloads,
    "video_link": videoLink == null
        ? []
        : List<dynamic>.from(videoLink!.map((x) => x)),
    "videos": videos == null
        ? []
        : List<dynamic>.from(videos!.map((x) => x.toJson())),
    "link": link,
    "brand": brand?.toJson(),
    "wholesale": wholesale == null
        ? []
        : List<dynamic>.from(wholesale!.map((x) => x.toJson())),
  };
}

class Brand {
  Brand({this.id, this.slug, this.name, this.logo});
  int? id;
  String? slug;
  String? name;
  String? logo;
  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json["id"],
    slug: json["slug"],
    name: json["name"],
    logo: json["logo"],
  );
  Map<String, dynamic> toJson() => {
    "id": id,
    "slug": slug,
    "name": name,
    "logo": logo,
  };
}

class Photo {
  Photo({this.variant, this.path});
  String? variant;
  String? path;
  factory Photo.fromJson(Map<String, dynamic> json) =>
      Photo(variant: json["variant"], path: json["path"]);
  Map<String, dynamic> toJson() => {"variant": variant, "path": path};
}

class ChoiceOption {
  ChoiceOption({this.name, this.title, this.options});
  String? name;
  String? title;
  List<String>? options;
  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
    name: json["name"],
    title: json["title"],
    options: json["options"] == null
        ? []
        : List<String>.from(json["options"].map((x) => x)),
  );
  Map<String, dynamic> toJson() => {
    "name": name,
    "title": title,
    "options": options == null
        ? []
        : List<dynamic>.from(options!.map((x) => x)),
  };
}

class Wholesale {
  dynamic minQty;
  dynamic maxQty;
  dynamic price;
  Wholesale({this.minQty, this.maxQty, this.price});
  factory Wholesale.fromJson(Map<String, dynamic> json) => Wholesale(
    minQty: json["min_qty"],
    maxQty: json["max_qty"],
    price: json["price"],
  );
  Map<String, dynamic> toJson() => {
    "min_qty": minQty,
    "max_qty": maxQty,
    "price": price,
  };
}

class Video {
  Video({this.path, this.thumbnail});
  String? path;
  String? thumbnail;
  factory Video.fromJson(Map<String, dynamic> json) =>
      Video(path: json["path"], thumbnail: json["thumbnail"]);
  Map<String, dynamic> toJson() => {"path": path, "thumbnail": thumbnail};
}
