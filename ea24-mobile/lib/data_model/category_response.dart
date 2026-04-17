import 'dart:convert';

CategoryResponse categoryResponseFromJson(String str) =>
    CategoryResponse.fromJson(json.decode(str));

String categoryResponseToJson(CategoryResponse data) =>
    json.encode(data.toJson());

class CategoryResponse {
  CategoryResponse({this.categories, this.success, this.status});

  List<Category>? categories;
  bool? success;
  int? status;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      CategoryResponse(
        categories: json["data"] != null
            ? List<Category>.from(json["data"].map((x) => Category.fromJson(x)))
            : null,
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": categories != null
        ? List<dynamic>.from(categories!.map((x) => x.toJson()))
        : null,
    "success": success,
    "status": status,
  };
}

class Category {
  Category({
    this.id,
    this.name,
    this.slug,
    this.banner,
    this.icon,
    this.numberOfChildren,
    this.links,
    this.coverImage,
  });

  int? id;
  String? name;
  String? slug;
  String? banner;
  String? icon;
  int? numberOfChildren;
  Links? links;
  String? coverImage;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    slug: json["slug"],
    banner: json["banner"],
    icon: json["icon"],
    numberOfChildren: json["number_of_children"],
    links: json["links"] != null ? Links.fromJson(json["links"]) : null,
    coverImage: json["cover_image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "slug": slug,
    "banner": banner,
    "icon": icon,
    "number_of_children": numberOfChildren,
    "links": links?.toJson(),
    "cover_image": coverImage,
  };
}

class Links {
  Links({this.products, this.subCategories});

  String? products;
  String? subCategories;

  factory Links.fromJson(Map<String, dynamic> json) =>
      Links(products: json["products"], subCategories: json["sub_categories"]);

  Map<String, dynamic> toJson() => {
    "products": products,
    "sub_categories": subCategories,
  };
}
