import 'dart:convert';

CartSummaryResponse cartSummaryResponseFromJson(String str) =>
    CartSummaryResponse.fromJson(json.decode(str));

String cartSummaryResponseToJson(CartSummaryResponse data) =>
    json.encode(data.toJson());

class CartSummaryResponse {
  String? subTotal;
  String? tax;
  String? gst;
  String? shippingCost;
  String? discount;
  dynamic grandTotal;
  double? grandTotalValue;
  String? couponCode;
  bool? couponApplied;
  int? totalProduct;
  int? clubPoint;

  CartSummaryResponse({
    this.subTotal,
    this.tax,
    this.gst,
    this.shippingCost,
    this.discount,
    this.grandTotal,
    this.grandTotalValue,
    this.couponCode,
    this.couponApplied,
    this.totalProduct,
    this.clubPoint,
  });

  factory CartSummaryResponse.fromJson(Map<String, dynamic> json) =>
      CartSummaryResponse(
        subTotal: json["sub_total"],
        tax: json["tax"],
        gst: json["gst"],
        shippingCost: json["shipping_cost"],
        discount: json["discount"],
        grandTotal: json["grand_total"],
        grandTotalValue:
            double.tryParse(json["grand_total_value"].toString()) ?? 0.0,
        couponCode: json["coupon_code"],
        couponApplied: json["coupon_applied"],
        totalProduct: json["total_items"],
        clubPoint: json["club_point"],
      );

  Map<String, dynamic> toJson() => {
    "sub_total": subTotal,
    "tax": tax,
    "gst": gst,
    "shipping_cost": shippingCost,
    "discount": discount,
    "grand_total": grandTotal,
    "grand_total_value": grandTotalValue,
    "coupon_code": couponCode,
    "coupon_applied": couponApplied,
    "total_items": totalProduct,
    "club_point": clubPoint,
  };
}
