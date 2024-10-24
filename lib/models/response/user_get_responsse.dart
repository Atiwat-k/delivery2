// To parse this JSON data, do
//
//     final userGetResponsse = userGetResponsseFromJson(jsonString);

import 'dart:convert';

UserGetResponsse userGetResponsseFromJson(String str) =>
    UserGetResponsse.fromJson(json.decode(str));

String userGetResponsseToJson(UserGetResponsse data) =>
    json.encode(data.toJson());

class UserGetResponsse {
  int uid;
  String name;
  String phone;
  String password;
  String address;
  String gps;
  String image;

  UserGetResponsse({
    required this.uid,
    required this.name,
    required this.phone,
    required this.password,
    required this.address,
    required this.gps,
    required this.image,
  });

  factory UserGetResponsse.fromJson(Map<String, dynamic> json) =>
      UserGetResponsse(
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
