import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class GPSandMapPage extends StatefulWidget {
  const GPSandMapPage({super.key});

  @override
  State<GPSandMapPage> createState() => _GPSandMapPageState();
}

class _GPSandMapPageState extends State<GPSandMapPage>
    with WidgetsBindingObserver {
  LatLng latLng = const LatLng(0, 0);
  MapController mapController = MapController();
  String address = "";
  bool isLoading = true;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      var position = await _determinePosition();
      log('${position.latitude} ${position.longitude}');
      latLng = LatLng(position.latitude, position.longitude);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(latLng, 16.0);
      });
      await _getAddressFromLatLng(latLng);
    } catch (e) {
      log("Error occurred while fetching location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      latLng = tappedPoint;
      isLoading = true;
    });

    mapController.move(tappedPoint, 16.0);
    await _getAddressFromLatLng(tappedPoint);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getCoordinatesFromAddress(String address) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        var location = locations.first;
        latLng = LatLng(location.latitude, location.longitude);
        mapController.move(latLng, 16.0);

        // อัปเดตที่อยู่จากพิกัดใหม่
        await _getAddressFromLatLng(latLng);
      } else {
        setState(() {
          address = 'ไม่พบตำแหน่งจากที่อยู่';
        });
      }
    } catch (e) {
      log("Error occurred while fetching coordinates: $e");
      setState(() {
        address = 'เกิดข้อผิดพลาดในการค้นหาตำแหน่ง';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS and Map'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'กรอกที่อยู่',
                                hintText: 'เช่น 123 Main St, City, Country',
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 10), // เพิ่มช่องว่างระหว่างช่องกรอกและปุ่ม
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                              });
                              _getCoordinatesFromAddress(
                                  _addressController.text);
                            },
                            child: const Text('ค้นหาตำแหน่ง'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(address.isNotEmpty
                          ? 'ที่อยู่ที่ได้จากพิกัด: $address\nพิกัด GPS: (${latLng.latitude}, ${latLng.longitude})'
                          : 'ไม่พบที่อยู่หรือพิกัด'),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: 15.0,
                      onTap: (tapPosition, tappedPoint) {
                        _onMapTap(tappedPoint);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        maxNativeZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 40,
                            height: 40,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.gps_fixed_sharp,
                                size: 30,
                                color: Color.fromARGB(255, 251, 50, 5),
                              ),
                            ),
                            alignment: Alignment.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, latLng);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'ยืนยันการปักหมุด',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      log(placemarks.toString());
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

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
}
