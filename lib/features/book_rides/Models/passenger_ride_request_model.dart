// To parse this JSON data, do
//
//     final passengerRideRequestModel = passengerRideRequestModelFromJson(jsonString);

import 'dart:convert';

PassengerRideRequestModel passengerRideRequestModelFromJson(String str) => PassengerRideRequestModel.fromJson(json.decode(str));

String passengerRideRequestModelToJson(PassengerRideRequestModel data) => json.encode(data.toJson());

class PassengerRideRequestModel {
  String? id;
  String? passengerId;
  String? fromCity;
  double? fromLat;
  double? fromLng;
  String? toCity;
  double? toLat;
  double? toLng;
  String? preferredDate;
  dynamic preferredTime;
  dynamic arrivalTime;
  int? seatsNeeded;
  String? rideType;
  String? tripType;
  dynamic returnDate;
  dynamic returnTime;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  PassengerRideRequestModel({
    this.id,
    this.passengerId,
    this.fromCity,
    this.fromLat,
    this.fromLng,
    this.toCity,
    this.toLat,
    this.toLng,
    this.preferredDate,
    this.preferredTime,
    this.arrivalTime,
    this.seatsNeeded,
    this.rideType,
    this.tripType,
    this.returnDate,
    this.returnTime,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PassengerRideRequestModel.fromJson(Map<String, dynamic> json) => PassengerRideRequestModel(
    id: json["id"],
    passengerId: json["passengerId"],
    fromCity: json["fromCity"],
    fromLat: json["fromLat"]?.toDouble(),
    fromLng: json["fromLng"]?.toDouble(),
    toCity: json["toCity"],
    toLat: json["toLat"]?.toDouble(),
    toLng: json["toLng"]?.toDouble(),
    preferredDate: json["preferredDate"],
    preferredTime: json["preferredTime"],
    arrivalTime: json["arrivalTime"],
    seatsNeeded: json["seatsNeeded"],
    rideType: json["rideType"],
    tripType: json["tripType"],
    returnDate: json["returnDate"],
    returnTime: json["returnTime"],
    status: json["status"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "passengerId": passengerId,
    "fromCity": fromCity,
    "fromLat": fromLat,
    "fromLng": fromLng,
    "toCity": toCity,
    "toLat": toLat,
    "toLng": toLng,
    "preferredDate": preferredDate,
    "preferredTime": preferredTime,
    "arrivalTime": arrivalTime,
    "seatsNeeded": seatsNeeded,
    "rideType": rideType,
    "tripType": tripType,
    "returnDate": returnDate,
    "returnTime": returnTime,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
