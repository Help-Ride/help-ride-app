// To parse this JSON data, do
//
//     final passengerMyRideList = passengerMyRideListFromJson(jsonString);

import 'dart:convert';

List<PassengerMyRideList> passengerMyRideListFromJson(String str) => List<PassengerMyRideList>.from(json.decode(str).map((x) => PassengerMyRideList.fromJson(x)));

String passengerMyRideListToJson(List<PassengerMyRideList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PassengerMyRideList {
  String? id;
  String? rideId;
  String? passengerId;
  int? seatsBooked;
  String? status;
  String? paymentStatus;
  dynamic stripePaymentIntentId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Ride? ride;

  PassengerMyRideList({
    this.id,
    this.rideId,
    this.passengerId,
    this.seatsBooked,
    this.status,
    this.paymentStatus,
    this.stripePaymentIntentId,
    this.createdAt,
    this.updatedAt,
    this.ride,
  });

  factory PassengerMyRideList.fromJson(Map<String, dynamic> json) => PassengerMyRideList(
    id: json["id"],
    rideId: json["rideId"],
    passengerId: json["passengerId"],
    seatsBooked: json["seatsBooked"],
    status: json["status"],
    paymentStatus: json["paymentStatus"],
    stripePaymentIntentId: json["stripePaymentIntentId"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    ride: json["ride"] == null ? null : Ride.fromJson(json["ride"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "rideId": rideId,
    "passengerId": passengerId,
    "seatsBooked": seatsBooked,
    "status": status,
    "paymentStatus": paymentStatus,
    "stripePaymentIntentId": stripePaymentIntentId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "ride": ride?.toJson(),
  };
}

class Ride {
  String? id;
  String? fromCity;
  String? toCity;
  DateTime? startTime;
  String? pricePerSeat;
  String? driverId;

  Ride({
    this.id,
    this.fromCity,
    this.toCity,
    this.startTime,
    this.pricePerSeat,
    this.driverId,
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    id: json["id"],
    fromCity: json["fromCity"],
    toCity: json["toCity"],
    startTime: json["startTime"] == null ? null : DateTime.parse(json["startTime"]),
    pricePerSeat: json["pricePerSeat"],
    driverId: json["driverId"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fromCity": fromCity,
    "toCity": toCity,
    "startTime": startTime?.toIso8601String(),
    "pricePerSeat": pricePerSeat,
    "driverId": driverId,
  };
}
