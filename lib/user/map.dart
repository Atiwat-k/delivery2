import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  final int shipmentId;
  final String pickupLocation;
  final String deliveryLocation;

  const MapScreen({
    Key? key,
    required this.shipmentId,
    required this.pickupLocation,
    required this.deliveryLocation,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  String address = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setMarkers();
  }

  // Function to convert an address to coordinates
  Future<LatLng> _getCoordinates(String location) async {
    // Replace this with actual geocoding logic if needed
    if (location == widget.pickupLocation) {
      return LatLng(13.736717, 100.523186); // Coordinates for pickup
    } else if (location == widget.deliveryLocation) {
      return LatLng(13.756331, 100.501765); // Coordinates for delivery
    }
    throw Exception('Location not recognized');
  }

  // Set markers on the map
  void _setMarkers() async {
    try {
      LatLng pickupLatLng = await _getCoordinates(widget.pickupLocation);
      LatLng deliveryLatLng = await _getCoordinates(widget.deliveryLocation);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('pickup'),
            position: pickupLatLng,
            infoWindow: InfoWindow(title: 'Pickup Location'),
          ),
        );
        _markers.add(
          Marker(
            markerId: MarkerId('delivery'),
            position: deliveryLatLng,
            infoWindow: InfoWindow(title: 'Delivery Location'),
          ),
        );
      });
    } catch (e) {
      log("Error occurred while setting markers: $e");
      setState(() {
        address = 'เกิดข้อผิดพลาดในการตั้งค่า Marker';
      });
    } finally {
      setState(() {
        isLoading = false; // Update loading state
      });
    }
  }

  // Default camera position
  LatLng _initialCameraPosition =
      LatLng(13.736717, 100.523186); // Bangkok coordinates

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shipment #${widget.shipmentId} Map'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(_initialCameraPosition),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Function to get address from coordinates
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          address =
              '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        });
      } else {
        setState(() {
          address = 'ไม่พบข้อมูลที่อยู่';
        });
      }
    } catch (e) {
      log("Error occurred while fetching address: $e");
      setState(() {
        address = 'เกิดข้อผิดพลาดในการดึงข้อมูลที่อยู่';
      });
    }
  }
}
