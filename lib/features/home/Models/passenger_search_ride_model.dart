// To parse this JSON data, do
//
//     final passengerSearchRidesModel = passengerSearchRidesModelFromJson(jsonString);

import 'dart:convert';

List<PassengerSearchRidesModel> passengerSearchRidesModelFromJson(String str) => List<PassengerSearchRidesModel>.from(json.decode(str).map((x) => PassengerSearchRidesModel.fromJson(x)));

String passengerSearchRidesModelToJson(List<PassengerSearchRidesModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PassengerSearchRidesModel {
  String? id;
  String? driverId;
  String? fromCity;
  double? fromLat;
  double? fromLng;
  String? toCity;
  double? toLat;
  double? toLng;
  DateTime? startTime;
  dynamic arrivalTime;
  String? pricePerSeat;
  int? seatsTotal;
  int? seatsAvailable;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  Driver? driver;

  PassengerSearchRidesModel({
    this.id,
    this.driverId,
    this.fromCity,
    this.fromLat,
    this.fromLng,
    this.toCity,
    this.toLat,
    this.toLng,
    this.startTime,
    this.arrivalTime,
    this.pricePerSeat,
    this.seatsTotal,
    this.seatsAvailable,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.driver,
  });

  factory PassengerSearchRidesModel.fromJson(Map<String, dynamic> json) => PassengerSearchRidesModel(
    id: json["id"],
    driverId: json["driverId"],
    fromCity: json["fromCity"],
    fromLat: json["fromLat"]?.toDouble(),
    fromLng: json["fromLng"]?.toDouble(),
    toCity: json["toCity"],
    toLat: json["toLat"]?.toDouble(),
    toLng: json["toLng"]?.toDouble(),
    startTime: json["startTime"] == null ? null : DateTime.parse(json["startTime"]),
    arrivalTime: json["arrivalTime"],
    pricePerSeat: json["pricePerSeat"],
    seatsTotal: json["seatsTotal"],
    seatsAvailable: json["seatsAvailable"],
    status: json["status"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    driver: json["driver"] == null ? null : Driver.fromJson(json["driver"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "driverId": driverId,
    "fromCity": fromCity,
    "fromLat": fromLat,
    "fromLng": fromLng,
    "toCity": toCity,
    "toLat": toLat,
    "toLng": toLng,
    "startTime": startTime?.toIso8601String(),
    "arrivalTime": arrivalTime,
    "pricePerSeat": pricePerSeat,
    "seatsTotal": seatsTotal,
    "seatsAvailable": seatsAvailable,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "driver": driver?.toJson(),
  };
}

class Driver {
  String? id;
  String? name;
  String? providerAvatarUrl;

  Driver({
    this.id,
    this.name,
    this.providerAvatarUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json["id"],
    name: json["name"],
    providerAvatarUrl: json["providerAvatarUrl"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "providerAvatarUrl": providerAvatarUrl,
  };
}
