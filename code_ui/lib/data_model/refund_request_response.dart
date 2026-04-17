// To parse this JSON data, do
//
//     final refundRequestResponse = refundRequestResponseFromJson(jsonString);

import 'dart:convert';

RefundRequestResponse refundRequestResponseFromJson(String str) =>
    RefundRequestResponse.fromJson(json.decode(str));

String refundRequestResponseToJson(RefundRequestResponse data) =>
    json.encode(data.toJson());

class RefundRequestResponse {
  RefundRequestResponse({
    this.refundRequests,
    this.links,
    this.meta,
    this.success,
    this.status,
  });

  List<RefundRequest>? refundRequests;
  Links? links;
  Meta? meta;
  bool? success;
  int? status;

  factory RefundRequestResponse.fromJson(Map<String, dynamic> json) =>
      RefundRequestResponse(
        refundRequests: List<RefundRequest>.from(
          json["data"].map((x) => RefundRequest.fromJson(x)),
        ),
        links: Links.fromJson(json["links"]),
        meta: Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(refundRequests!.map((x) => x.toJson())),
    "links": links!.toJson(),
    "meta": meta!.toJson(),
    "success": success,
    "status": status,
  };
}

class RefundRequest {
  RefundRequest({
    this.id,
    this.userId,
    this.orderCode,
    this.productName,
    this.productPrice,
    this.refundStatus,
    this.refundLabel,
    this.date,
  });

  int? id;
  int? userId;
  String? orderCode;
  String? productName;
  String? productPrice;
  int? refundStatus;
  String? refundLabel;
  String? date;

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    id: json["id"],
    userId: json["user_id"],
    orderCode: json["order_code"],
    productName: json["product_name"],
    productPrice: json["product_price"],
    refundStatus: json["refund_status"],
    refundLabel: json["refund_label"],
    date: json["date"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "order_code": orderCode,
    "product_name": productName,
    "product_price": productPrice,
    "refund_status": refundStatus,
    "refund_label": refundLabel,
    "date": date,
  };
}

class Links {
  Links({this.first, this.last, this.prev, this.next});

  String? first;
  String? last;
  dynamic prev;
  String? next;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    first: json["first"],
    last: json["last"],
    prev: json["prev"],
    next: json["next"],
  );

  Map<String, dynamic> toJson() => {
    "first": first,
    "last": last,
    "prev": prev,
    "next": next,
  };
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
