import 'dart:convert';

ReviewResponse reviewResponseFromJson(String str) =>
    ReviewResponse.fromJson(json.decode(str));

String reviewResponseToJson(ReviewResponse data) => json.encode(data.toJson());

class ReviewResponse {
  ReviewResponse({this.reviews, this.meta, this.success, this.status});

  List<Review>? reviews;
  Meta? meta;
  bool? success;
  int? status;

  factory ReviewResponse.fromJson(Map<String, dynamic> json) => ReviewResponse(
    reviews: json["data"] != null
        ? List<Review>.from(json["data"].map((x) => Review.fromJson(x)))
        : [],
    meta: json["meta"] != null ? Meta.fromJson(json["meta"]) : null,
    success: json["success"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "data": reviews != null
        ? List<dynamic>.from(reviews!.map((x) => x.toJson()))
        : null,
    "meta": meta?.toJson(),
    "success": success,
    "status": status,
  };
}

class Review {
  Review({
    this.userId,
    this.userName,
    this.avatar,
    this.images,
    this.rating,
    this.comment,
    this.time,
  });

  int? userId;
  String? userName;
  String? avatar;
  List<ReviewImage>? images;
  double? rating;
  String? comment;
  String? time;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    userId: json["user_id"],
    userName: json["user_name"],
    avatar: json["avatar"],

    images: json["images"] != null
        ? List<ReviewImage>.from(
            json["images"].map((x) => ReviewImage.fromJson(x)),
          )
        : [],
    rating: json["rating"].toDouble(),
    comment: json["comment"],
    time: json["time"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "user_name": userName,
    "avatar": avatar,

    "images": images != null
        ? List<dynamic>.from(images!.map((x) => x.toJson()))
        : [],
    "rating": rating,
    "comment": comment,
    "time": time,
  };
}

class ReviewImage {
  String? path;

  ReviewImage({this.path});

  factory ReviewImage.fromJson(Map<String, dynamic> json) =>
      ReviewImage(path: json["path"]);

  Map<String, dynamic> toJson() => {"path": path};
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
