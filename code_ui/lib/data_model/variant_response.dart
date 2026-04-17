// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

VariantResponse variantResponseFromJson(String str) =>
    VariantResponse.fromJson(json.decode(str));

String variantResponseToJson(VariantResponse data) =>
    json.encode(data.toJson());

class VariantResponse {
  bool? result;
  VariantData? variantData;

  VariantResponse({this.result, this.variantData});

  factory VariantResponse.fromJson(Map<String, dynamic> json) =>
      VariantResponse(
        result: json["result"],
        // THIS IS THE FIX: Check if "data" is null before trying to parse it.
        variantData: json["data"] == null
            ? null
            : VariantData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "result": result,
    "data": variantData?.toJson(),
  };
}

class VariantData {
  String? price;
  int? stock;
  var stockTxt;
  int? digital;
  String? variant;
  String? variation;
  int? maxLimit;
  int? inStock;
  String? image;

  VariantData({
    this.price,
    this.stock,
    this.stockTxt,
    this.digital,
    this.variant,
    this.variation,
    this.maxLimit,
    this.inStock,
    this.image,
  });

  factory VariantData.fromJson(Map<String, dynamic> json) => VariantData(
    price: json["price"],

    stock: int.tryParse(json["stock"]?.toString() ?? '0') ?? 0,
    stockTxt: json["stock_txt"],
    digital: int.tryParse(json["digital"]?.toString() ?? '0') ?? 0,
    variant: json["variant"],
    variation: json["variation"],
    maxLimit: int.tryParse(json["max_limit"]?.toString() ?? '0') ?? 0,
    inStock: int.tryParse(json["in_stock"]?.toString() ?? '0') ?? 0,
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "price": price,
    "stock": stock,
    "digital": digital,
    "variant": variant,
    "variation": variation,
    "max_limit": maxLimit,
    "in_stock": inStock,
    "image": image,
  };
}
