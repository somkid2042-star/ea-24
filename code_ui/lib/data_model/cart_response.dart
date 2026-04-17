import 'dart:convert';

CartResponse cartResponseFromJson(String str) =>
    CartResponse.fromJson(json.decode(str));

String cartResponseToJson(CartResponse data) => json.encode(data.toJson());

class CartResponse {
  String? grandTotal;
  List<Datum>? data;

  CartResponse({this.grandTotal, this.data});

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    grandTotal: json["grand_total"]?.toString(),
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "grand_total": grandTotal,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  String? name;
  int? ownerId;
  String? subTotal;
  List<CartItem>? cartItems;

  Datum({this.name, this.ownerId, this.subTotal, this.cartItems});

  factory Datum.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integer values
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return Datum(
      name: json["name"]?.toString(),
      ownerId: safeParseInt(json["owner_id"]),
      subTotal: json["sub_total"]?.toString(),
      cartItems: json["cart_items"] == null
          ? []
          : List<CartItem>.from(
              json["cart_items"]!.map((x) => CartItem.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "owner_id": ownerId,
    "sub_total": subTotal,
    "cart_items": cartItems == null
        ? []
        : List<dynamic>.from(cartItems!.map((x) => x.toJson())),
  };
}

class CartItem {
  int? id;
  int? ownerId;
  int? userId;
  int? productId;
  String? productName;
  int? auctionProduct;
  String? productThumbnailImage;
  String? variation;
  String? price;
  String? currencySymbol;
  String? tax;
  String? gst;
  int? shippingCost;
  int? quantity;
  int? lowerLimit;
  int? upperLimit;
  int? digital;
  int? stock;

  CartItem({
    this.id,
    this.ownerId,
    this.userId,
    this.productId,
    this.productName,
    this.auctionProduct,
    this.productThumbnailImage,
    this.variation,
    this.price,
    this.currencySymbol,
    this.tax,
    this.gst,
    this.shippingCost,
    this.quantity,
    this.lowerLimit,
    this.upperLimit,
    this.digital,
    this.stock,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return CartItem(
      id: safeParseInt(json["id"]),
      ownerId: safeParseInt(json["owner_id"]),
      userId: safeParseInt(json["user_id"]),
      productId: safeParseInt(json["product_id"]),
      auctionProduct: safeParseInt(json["auction_product"]),
      shippingCost: safeParseInt(json["shipping_cost"]),
      quantity: safeParseInt(json["quantity"]),
      lowerLimit: safeParseInt(json["lower_limit"]),
      upperLimit: safeParseInt(json["upper_limit"]),
      digital: safeParseInt(json["digital"]),
      stock: safeParseInt(json["stock"]),
      productName: json["product_name"]?.toString(),
      productThumbnailImage: json["product_thumbnail_image"]?.toString(),
      variation: json["variation"]?.toString(),
      price: json["price"]?.toString(),
      currencySymbol: json["currency_symbol"]?.toString(),
      tax: json["tax"]?.toString(),
      gst: json["gst"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "owner_id": ownerId,
    "user_id": userId,
    "product_id": productId,
    "product_name": productName,
    "auction_product": auctionProduct,
    "product_thumbnail_image": productThumbnailImage,
    "variation": variation,
    "price": price,
    "currency_symbol": currencySymbol,
    "tax": tax,
    "gst": gst,
    "shipping_cost": shippingCost,
    "quantity": quantity,
    "lower_limit": lowerLimit,
    "upper_limit": upperLimit,
    "digital": digital,
    "stock": stock,
  };
}
