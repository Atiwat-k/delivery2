import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/config/internal_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ShipmentScreen extends StatefulWidget {
  final int senderId;
  final String senderGPS;
  final int receiverId;
  final String receiverGPS;
  LatLng latLng = const LatLng(0, 0);
  MapController mapController = MapController();
  bool isLoading = false;

  ShipmentScreen(
      this.senderId, this.senderGPS, this.receiverId, this.receiverGPS);

  @override
  _ShipmentScreenState createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final TextEditingController descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Shipment')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      height: 200,
                      width: double.infinity,
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.camera_alt,
                                  size: 70,
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDescriptionField(),
                  SizedBox(height: 16),
                  _buildConfirmButton(),
                  SizedBox(height: 16),
                  _buildMap(), // แสดงแผนที่
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "รายละเอียดของการจัดส่ง",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(5, 5, 1, 1),
              ),
              maxLines: null,
              minLines: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          minimumSize: const Size(double.infinity, 45),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ยืนยัน",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(width: 10),
            Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 300,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          // ตั้งค่า initialCenter เป็นตำแหน่งของผู้รับ
          initialCenter: LatLng(
            double.parse(widget.receiverGPS.split(',')[0]),
            double.parse(widget.receiverGPS.split(',')[1]),
          ),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
            maxNativeZoom: 19,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  double.parse(widget.receiverGPS.split(',')[0]),
                  double.parse(widget.receiverGPS.split(',')[1]),
                ),
                width: 40,
                height: 40,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
                alignment: Alignment.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final choice = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          actions: [
            TextButton(
              child: Text('Camera'),
              onPressed: () => Navigator.pop(context, ImageSource.camera),
            ),
            TextButton(
              child: Text('Gallery'),
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        );
      },
    );

    if (choice != null) {
      final pickedFile = await picker.getImage(source: choice);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _createShipment() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image.')),
      );
      return;
    }

    final fileExtension = _image!.path.split('.').last.toLowerCase();
    if (!['png', 'jpg', 'jpeg'].contains(fileExtension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('โปรดเลือกไฟล์รูปภาพที่ถูกต้อง (PNG, JPG, JPEG)')),
      );
      return;
    }

    final uri = Uri.parse('$API_ENDPOINT/shipments/shipments');
    final request = http.MultipartRequest('POST', uri);

    request.fields['sender_id'] = widget.senderId.toString();
    request.fields['receiver_id'] = widget.receiverId.toString();
    request.fields['description'] = descriptionController.text;
    request.fields['pickup_location'] = widget.senderGPS;
    request.fields['delivery_location'] = widget.receiverGPS;
    request.fields['status'] = '1'; // สถานะเริ่มต้นเป็น 1 (รอการรับสินค้า)

    var imageFile = await http.MultipartFile.fromPath(
      'image',
      _image!.path,
      contentType: MediaType('image', fileExtension),
    );

    request.files.add(imageFile);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await request.send();

      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        int shipmentId = data['shipment_id'];

        await _addShipmentToFirestore(shipmentId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );

        Navigator.pop(context);
      } else {
        final responseData = await response.stream.bytesToString();
        final errorData = json.decode(responseData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งข้อมูล: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addShipmentToFirestore(int shipmentId) async {
    final docRef = FirebaseFirestore.instance.collection('shipments').doc();

    await docRef.set({
      'shipment_id': shipmentId,
      'sender_id': widget.senderId,
      'receiver_id': widget.receiverId,
      'description': descriptionController.text,
      'pickup_location': widget.senderGPS,
      'delivery_location': widget.receiverGPS,
      'status': '1',
    });
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการสร้างการจัดส่ง'),
          content: Text('คุณต้องการสร้างการจัดส่งนี้หรือไม่?'),
          actions: [
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('ยืนยัน'),
              onPressed: () {
                Navigator.of(context).pop();
                _createShipment();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // โค้ดที่ใช้สำหรับการดึงตำแหน่งปัจจุบันจะอยู่ที่นี่
  }
}
