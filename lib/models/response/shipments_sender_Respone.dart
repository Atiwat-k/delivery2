// To parse this JSON data, do
//
//     final shipmentsSenderRespone = shipmentsSenderResponeFromJson(jsonString);

import 'dart:convert';

List<ShipmentsSenderRespone> shipmentsSenderResponeFromJson(String str) =>
    List<ShipmentsSenderRespone>.from(
        json.decode(str).map((x) => ShipmentsSenderRespone.fromJson(x)));

String shipmentsSenderResponeToJson(List<ShipmentsSenderRespone> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ShipmentsSenderRespone {
  int receiverUid;
  String receiverName;
  String receiverPhone;
  String receiverImage;
  String receiverGps;
  int senderUid;
  String senderName;
  String senderPhone;
  String senderImage;
  String senderGps;
  int status;
  int shipmentId;
  int senderId;

  ShipmentsSenderRespone({
    required this.receiverUid,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverImage,
    required this.receiverGps,
    required this.senderUid,
    required this.senderName,
    required this.senderPhone,
    required this.senderImage,
    required this.senderGps,
    required this.status,
    required this.shipmentId,
    required this.senderId,
  });

  factory ShipmentsSenderRespone.fromJson(Map<String, dynamic> json) =>
      ShipmentsSenderRespone(
        receiverUid: json["receiver_uid"],
        receiverName: json["receiver_name"],
        receiverPhone: json["receiver_phone"],
        receiverImage: json["receiver_image"],
        receiverGps: json["receiver_gps"],
        senderUid: json["sender_uid"],
        senderName: json["sender_name"],
        senderPhone: json["sender_phone"],
        senderImage: json["sender_image"],
        senderGps: json["sender_gps"],
        status: json["status"],
        shipmentId: json["shipment_id"],
        senderId: json["sender_id"],
      );

  Map<String, dynamic> toJson() => {
        "receiver_uid": receiverUid,
        "receiver_name": receiverName,
        "receiver_phone": receiverPhone,
        "receiver_image": receiverImage,
        "receiver_gps": receiverGps,
        "sender_uid": senderUid,
        "sender_name": senderName,
        "sender_phone": senderPhone,
        "sender_image": senderImage,
        "sender_gps": senderGps,
        "status": status,
        "shipment_id": shipmentId,
        "sender_id": senderId,
      };
}
