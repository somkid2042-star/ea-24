
import 'dart:convert';

AddressResponse addressResponseFromJson(String str) =>
    AddressResponse.fromJson(json.decode(str));

String addressResponseToJson(AddressResponse data) =>
    json.encode(data.toJson());

class AddressResponse {
  AddressResponse({this.addresses, this.success, this.status});

  List<Address>? addresses;
  bool? success;
  int? status;

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      AddressResponse(
        addresses: List<Address>.from(
          json["data"].map((x) => Address.fromJson(x)),
        ),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(addresses!.map((x) => x.toJson())),
    "success": success,
    "status": status,
  };
}

class Address {
  Address({
    this.id,
    this.userId,
    this.address,
    this.countryId,
    this.stateId,
    this.cityId,
    this.areaId,
    this.countryName,
    this.stateName,
    this.cityName,
    this.areaName,
    this.postalCode,
    this.phone,
    this.setDefault,
    this.setBilling,
    this.locationAvailable,
    this.lat,
    this.lng,
    this.valid,
  });

  int? id;
  int? userId;
  String? address;
  int? countryId;
  int? stateId;
  int? cityId;
  int? areaId;
  String? countryName;
  String? stateName;
  String? cityName;
  String? areaName;
  String? postalCode;
  String? phone;
  int? setDefault;
  int? setBilling;
  bool? locationAvailable;
  double? lat;
  double? lng;
  bool? valid;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json["id"],
    userId: json["user_id"],
    address: json["address"],
    countryId: json["country_id"],
    stateId: json["state_id"],
    cityId: json["city_id"],
    areaId: json["area_id"],
    countryName: json["country_name"],
    stateName: json["state_name"],
    cityName: json["city_name"],
    areaName: json["area_name"],
    postalCode: json["postal_code"] ?? "",
    phone: json["phone"] ?? "",
    setDefault: json["set_default"],
    setBilling: json["set_billing"],
    locationAvailable: json["location_available"],
    lat: json["lat"] != null ? double.tryParse(json["lat"].toString()) : null,

    lng: json["lang"] != null ? double.tryParse(json["lang"].toString()) : null,

    valid: json["valid"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "address": address,
    "country_id": countryId,
    "state_id": stateId,
    "city_id": cityId,
    "area_id": areaId,
    "country_name": countryName,
    "state_name": stateName,
    "city_name": cityName,
    "area_name": areaName,
    "postal_code": postalCode,
    "phone": phone,
    "set_default": setDefault,
    "set_billing": setBilling,
    "location_available": locationAvailable,
    "lat": lat,
    "lang": lng,
    "valid": valid,
  };
}
