// To parse this JSON data, do
//
//     final userGetAllResponsse = userGetAllResponsseFromJson(jsonString);

import 'dart:convert';

List<UserGetAllResponsse> userGetAllResponsseFromJson(String str) =>
    List<UserGetAllResponsse>.from(
        json.decode(str).map((x) => UserGetAllResponsse.fromJson(x)));

String userGetAllResponsseToJson(List<UserGetAllResponsse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserGetAllResponsse {
  int uid;
  String name;
  String phone;
  String password;
  String address;
  String gps;
  String image;

  UserGetAllResponsse({
    required this.uid,
    required this.name,
    required this.phone,
    required this.password,
    required this.address,
    required this.gps,
    required this.image,
  });

  factory UserGetAllResponsse.fromJson(Map<String, dynamic> json) =>
      UserGetAllResponsse(
        uid: json["uid"],
        name: json["name"],
        phone: json["phone"],
        password: json["password"],
        address: json["address"],
        gps: json["gps"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "phone": phone,
        "password": password,
        "address": address,
        "gps": gps,
        "image": image,
      };
}
