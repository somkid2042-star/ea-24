import 'dart:convert';

ProductMiniResponse productMiniResponseFromJson(String str) =>
    ProductMiniResponse.fromJson(json.decode(str));

String productMiniResponseToJson(ProductMiniResponse data) =>
    json.encode(data.toJson());

class ProductMiniResponse {
  ProductMiniResponse({this.products, this.meta, this.success, this.status});

  List<Product>? products;
  bool? success;
  int? status;
  Meta? meta;

  factory ProductMiniResponse.fromJson(Map<String, dynamic> json) =>
      ProductMiniResponse(
        products: json["data"] != null
            ? List<Product>.from(json["data"].map((x) => Product.fromJson(x)))
            : null,
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  get data => null;

  Map<String, dynamic> toJson() => {
    "data": products != null
        ? List<dynamic>.from(products!.map((x) => x.toJson()))
        : null,
    "meta": meta?.toJson(),
    "success": success,
    "status": status,
  };
}

class Product {
  Product({
    this.id,
    this.slug,
    this.name,
    this.thumbnailImage,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount,
    this.discount,
    this.rating,
    this.sales,
    this.links,
    this.isWholesale,
    this.reviewCount,
  });

  int? id;
  String? slug;
  String? name;
  String? thumbnailImage;
  String? mainPrice;
  String? strokedPrice;
  bool? hasDiscount;
  dynamic discount;
  double? rating;
  int? sales;
  Links? links;
  bool? isWholesale;
  int? reviewCount;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      slug: json["slug"],
      name: json["name"],
      thumbnailImage: json["thumbnail_image"],
      mainPrice: json["main_price"],
      strokedPrice: json["stroked_price"],
      hasDiscount: json["has_discount"],
      discount: json["discount"],
      rating: json["rating"] == null
          ? 0.0
          : double.tryParse(json["rating"].toString()) ?? 0.0,
      sales: json["sales"],
      links: json["links"] == null ? null : Links.fromJson(json["links"]),
      isWholesale: json["is_wholesale"],
      reviewCount: json["review_count"] == null
          ? 0
          : int.tryParse(json["review_count"].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "slug": slug,
    "name": name,
    "thumbnail_image": thumbnailImage,
    "main_price": mainPrice,
    "stroked_price": strokedPrice,
    "has_discount": hasDiscount,
    "discount": discount,
    "rating": rating,
    "sales": sales,
    "links": links?.toJson(),
    "is_wholesale": isWholesale,
    "review_count": reviewCount,
  };
}

class Links {
  Links({this.details});

  String? details;

  factory Links.fromJson(Map<String, dynamic> json) =>
      Links(details: json["details"]);

  Map<String, dynamic> toJson() => {"details": details};
}

class Meta {
  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  int? currentPage;
  int? from;
  int? lastPage;
  String? path;
  int? perPage;
  int? to;
  int? total;

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    currentPage: json["current_page"],
    from: json["from"],
    lastPage: json["last_page"],
    path: json["path"],
    perPage: json["per_page"],
    to: json["to"],
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "from": from,
    "last_page": lastPage,
    "path": path,
    "per_page": perPage,
    "to": to,
    "total": total,
  };
}
