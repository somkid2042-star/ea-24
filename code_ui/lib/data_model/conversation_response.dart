import 'dart:convert';

ConversationResponse conversationResponseFromJson(String str) =>
    ConversationResponse.fromJson(json.decode(str));

String conversationResponseToJson(ConversationResponse data) =>
    json.encode(data.toJson());

class ConversationResponse {
  ConversationResponse({
    this.conversationItemList,
    this.meta,
    this.success,
    this.status,
  });

  List<ConversationItem>? conversationItemList;
  Meta? meta;
  bool? success;
  int? status;

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      ConversationResponse(
        conversationItemList: List<ConversationItem>.from(
          json["data"].map((x) => ConversationItem.fromJson(x)),
        ),
        meta: Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(conversationItemList!.map((x) => x.toJson())),
    "meta": meta!.toJson(),
    "success": success,
    "status": status,
  };
}

class ConversationItem {
  ConversationItem({
    this.id,
    this.receiverId,
    this.receiverType,
    this.shopId,
    this.shopName,
    this.shopLogo,
    this.title,
    this.senderViewed,
    this.receiverViewed,
    this.date,
  });

  int? id;
  int? receiverId;
  String? receiverType;
  int? shopId;
  String? shopName;
  String? shopLogo;
  String? title;
  int? senderViewed;
  int? receiverViewed;
  DateTime? date;

  factory ConversationItem.fromJson(Map<String, dynamic> json) =>
      ConversationItem(
        id: json["id"],
        receiverId: json["receiver_id"],
        receiverType: json["receiver_type"],
        shopId: json["shop_id"],
        shopName: json["shop_name"],
        shopLogo: json["shop_logo"],
        title: json["title"],
        senderViewed: json["sender_viewed"],
        receiverViewed: json["receiver_viewed"],
        date: DateTime.parse(json["date"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "receiver_id": receiverId,
    "receiver_type": receiverType,
    "shop_id": shopId,
    "shop_name": shopName,
    "shop_logo": shopLogo,
    "title": title,
    "sender_viewed": senderViewed,
    "receiver_viewed": receiverViewed,
    "date": date!.toIso8601String(),
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
