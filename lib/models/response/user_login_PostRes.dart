// To parse this JSON data, do
//
//     final userLoginPostRes = userLoginPostResFromJson(jsonString);

import 'dart:convert';

UserLoginPostRes userLoginPostResFromJson(String str) =>
    UserLoginPostRes.fromJson(json.decode(str));

String userLoginPostResToJson(UserLoginPostRes data) =>
    json.encode(data.toJson());

class UserLoginPostRes {
  String message;
  User user;

  UserLoginPostRes({
    required this.message,
    required this.user,
  });

  factory UserLoginPostRes.fromJson(Map<String, dynamic> json) =>
      UserLoginPostRes(
        message: json["message"],
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "user": user.toJson(),
      };
}

class User {
  int uid;
  String name;
  String phone;
  String address;
  String gps;
  String image;

  User({
    required this.uid,
    required this.name,
    required this.phone,
    required this.address,
    required this.gps,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"],
        phone: json["phone"],
        address: json["address"],
        gps: json["gps"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "phone": phone,
        "address": address,
        "gps": gps,
        "image": image,
      };
}
