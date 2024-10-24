import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/config/config.dart';

import 'package:delivery/login.dart';
import 'package:delivery/models/response/shipments_receiver_Respone.dart';
import 'package:delivery/models/response/shipments_sender_Respone.dart';
import 'package:delivery/models/response/user_get_all_responsse.dart';
import 'package:delivery/models/response/user_get_responsse.dart';
import 'package:delivery/user/map.dart';
import 'package:delivery/user/shipments.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class UserPage extends StatefulWidget {
  final int uid;

  UserPage({super.key, required this.uid});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int? _selectedIndex;
  String url = '';
  late UserGetResponsse userGetResponsse;
  late Future<void> loadData;
  late Future<void> loadshipments;
  String _searchPhone = '';
  List<UserGetAllResponsse> _searchResults = [];
  TextEditingController nameCtl = TextEditingController();
  List<ShipmentsSenderRespone> shipmentsSenderRespone = [];
  List<ShipmentsReceiverRespone> shipmentsreceiverRespone = [];
  bool _isLoading = false;
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> shipmentsDetails = [];
  late StreamSubscription listener;
  String s_id = "";

  @override
  void initState() {
    super.initState();
    loadData = _loadDataAsync();
    loadshipments = _fetchShipments();
  }

  Future<void> _loadDataAsync() async {
    var config = await Configguration.getConfig();
    url = config['apiEndpoint'];
    var res = await http.get(Uri.parse('$url/user/get-user/${widget.uid}'));
    log(res.body);
    userGetResponsse = userGetResponsseFromJson(res.body);
  }

  void _onIconButtonPressed(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // Reload shipments if the delivery section is selected
    if (_selectedIndex == 1) {
      await _fetchShipments(); // Fetch shipments again and wait for it to complete
    }

    if (_selectedIndex == 2) {
      await _fetchReceive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child:
                Image.asset('assets/images/turbo.png', height: 100, width: 100),
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 232, 232, 232),
        child: Center(child: _buildBody()),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 110,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            return _buildIconButton(
              index,
              [
                FontAwesomeIcons.home,
                FontAwesomeIcons.truck,
                FontAwesomeIcons.boxesStacked,
                FontAwesomeIcons.userLarge
              ][index],
              ["หน้าหลัก", "ส่งสินค้า", "รับสินค้า", "ฉัน"][index],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return _selectedIndex == null
        ? _buildHomeSection()
        : [
            _buildHomeSection(),
            _buildDeliverySection(),
            _buildReceiveSection(),
            _buildProfileSection()
          ][_selectedIndex!];
  }

  Widget _buildHomeSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(7.0),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Flexible(
                  flex: 3, // Search box takes more space
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'ใส่เบอร์เพื่อหาคนที่ต้องการจัดส่ง',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: const Icon(Icons.search), // Add search icon
                    ),
                    onChanged: (value) => setState(() => _searchPhone = value),
                  ),
                ),
                const SizedBox(width: 8), // Space between TextField and Button
                Flexible(
                  flex: 1, // Button takes less space
                  child: ElevatedButton(
                    onPressed: _searchUserByPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blueGrey, // Green background for button
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5), // Rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15), // Button padding
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white), // Search icon
                        SizedBox(width: 1), // Space between icon and text
                        Text('ค้นหา',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)), // Button text
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        _isLoading ? CircularProgressIndicator() : _buildSearchResults(),
      ],
    );
  }

  Future<void> _searchUserByPhone() async {
    if (_searchPhone.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      String apiUrl = '$url/search/search-user/$_searchPhone/${widget.uid}';
      var res = await http.get(Uri.parse(apiUrl));

      if (res.statusCode == 200) {
        _searchResults = userGetAllResponsseFromJson(res.body);
      } else {
        _searchResults = [];
        _showSnackBar('No users found');
      }
    } catch (error) {
      _showSnackBar('Error occurred: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(10, 150, 10, 10),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // จัดตำแหน่งให้อยู่ตรงกลาง
          crossAxisAlignment: CrossAxisAlignment.center, // จัดให้อยู่กลางแนวนอน
          children: [
            Icon(
              Icons.search,
              color: Colors.blueGrey, // สีของไอคsอน
              size: 100.0, // ขนาดของไอคอน
            ),
            Text(
              'ค้นหาคนที่ต้องการส่ง',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold, // สีของข้อความ
                fontSize: 30.0, // ขนาดของข้อความ
              ),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return Container(
            width: double.infinity, // ทำให้การ์ดกว้างเต็มที่
            height: 160, // กำหนดความสูงของการ์ด
            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),

            child: Card(
              color: Colors.white,
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.center, // จัดตำแหน่งให้กลาง
                      child: CircleAvatar(
                        radius: 60, // เพิ่มรัศมีของ CircleAvatar ให้ใหญ่ขึ้น
                        backgroundImage: NetworkImage(user.image),
                      ),
                    ),
                    SizedBox(width: 16), // ระยะห่างระหว่างรูปกับข้อความ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(15), // ทำให้มุมเป็นวงรี
                              color: Colors
                                  .grey[300], // กล่องสีเทาสำหรับชื่อและเบอร์
                            ),
                            padding: const EdgeInsets.fromLTRB(
                                10, 10, 50, 10), // ตั้งค่าระยะห่างภายใน
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ชื่อ: ${user.name}",
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold), // ทำให้ชื่อหนา
                                ),
                                const SizedBox(
                                    height: 4), // ระยะห่างระหว่างชื่อและเบอร์
                                Text(
                                    "เบอร์โทร: ${user.phone}"), // แสดงเบอร์โทรศัพท์
                              ],
                            ),
                          ),
                          const Spacer(), // เพิ่มระยะห่างให้ปุ่มอยู่ด้านล่าง
                          Center(
                            // จัดให้ปุ่มอยู่กลาง
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to ShipmentScreen with uid when button is pressed
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShipmentScreen(
                                        userGetResponsse.uid,
                                        userGetResponsse.gps,
                                        user.uid,
                                        user.gps), // Pass uid here
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green, // สีพื้นหลังของปุ่ม
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                  horizontal: 60.0,
                                ), // ตั้งค่าระยะห่างภายในปุ่ม
                              ),
                              child: const Text(
                                'เลือก',
                                style: TextStyle(
                                    color: Colors.white), // สีข้อความในปุ่ม
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchShipments() async {
    setState(() => _isLoading = true);
    shipmentsDetails.clear(); // ล้างข้อมูลก่อนเริ่มดึงใหม่

    try {
      // เรียกใช้งาน API เพื่อดึงข้อมูลการจัดส่ง
      var config = await Configguration.getConfig();
      url = config['apiEndpoint'];
      var res =
          await http.get(Uri.parse('$url/shipments/sender/${widget.uid}'));

      if (res.statusCode == 200) {
        shipmentsSenderRespone = shipmentsSenderResponeFromJson(res.body);
        log('Fetched shipments successfully');

        // สมัครรับข้อมูลแบบเรียลไทม์จาก Firestore สำหรับแต่ละ shipmentId
        for (var shipment in shipmentsSenderRespone) {
          var shipmentId = shipment.shipmentId;

          FirebaseFirestore.instance
              .collection('shipments')
              .doc(shipmentId.toString())
              .snapshots() // สมัครรับข้อมูลเรียลไทม์
              .listen((snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data();
              log('Shipment ID: ${data!['shipment_id'].toString()}');
              log('Sender ID: ${data['sender_id'].toString()}');
              log('Status: ${data['status'].toString()}');

              // ค้นหา shipment ในรายการและอัปเดตสถานะหรือเพิ่มใหม่
              var existingIndex = shipmentsDetails.indexWhere(
                  (element) => element['shipment_id'] == shipmentId);

              if (existingIndex >= 0) {
                // อัปเดตรายการที่มีอยู่
                shipmentsDetails[existingIndex] = data;
              } else {
                // เพิ่มรายการใหม่
                shipmentsDetails.add(data);
              }

              // อัปเดต UI
              setState(() {});
            } else {
              log("Document does not exist");
            }
          });
        }
      } else {
        _showSnackBar('Failed to load shipments');
      }
    } catch (error) {
      log('Error fetching shipments: $error');
      _showSnackBar('Error fetching shipments: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDeliverySection() {
    // Display a loading indicator while fetching data
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Handle case where no shipments are found
    if (shipmentsSenderRespone.isEmpty) {
      return Center(child: Text('No deliveries available'));
    }

    // Build the list of deliveries
    return ListView.builder(
      itemCount: shipmentsSenderRespone.length,
      itemBuilder: (context, index) {
        final delivery = shipmentsSenderRespone[index];
        final shipmentId = delivery.shipmentId;

        // ค้นหาข้อมูลสถานะที่ตรงกันจาก shipmentsDetails
        final statusData = shipmentsDetails.firstWhere(
          (element) => element['shipment_id'] == shipmentId,
          orElse: () => {'status': 0}, // ค่าเริ่มต้นถ้าไม่พบ
        );
        final status = statusData['status'];

        return Container(
          width: double.infinity,
          height: 160,
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
          child: Card(
            color: Colors.white,
            elevation: 10,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(delivery.receiverImage),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 45, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ชื่อ: ${delivery.receiverName}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("เบอร์โทร: ${delivery.receiverPhone}"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Function to convert status code to status text
  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "รอไรเดอร์รับสินค้า"; // Status 1
      case 2:
        return "ไรเดอร์รับงาน"; // Status 2
      case 3:
        return "ไรเดอร์รับสินค้าแล้ว"; // Status 3
      default:
        return "ไม่ทราบสถานะ"; // Default case
    }
  }

// Function to get the color based on status
  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color.fromARGB(255, 255, 0, 0); // Status 1 - Green
      case 2:
        return Colors.orange; // Status 2 - Orange
      case 3:
        return Colors.green; // Status 3 - Green
      default:
        return Colors.black; // Default color
    }
  }

  Future<void> _fetchReceive() async {
    setState(() => _isLoading = true);
    shipmentsDetails.clear(); // ล้างข้อมูลก่อนเริ่มดึงใหม่

    try {
      // เรียกใช้งาน API เพื่อดึงข้อมูลการจัดส่ง
      var config = await Configguration.getConfig();
      url = config['apiEndpoint'];
      var res = await http.get(Uri.parse(
          '$url/shipments/receiver/${widget.uid}')); // ดึงข้อมูล receiver ตาม uid

      if (res.statusCode == 200) {
        shipmentsreceiverRespone = shipmentsReceiverResponeFromJson(res.body);
        log('Fetched shipments successfully');

        // สมัครรับข้อมูลแบบเรียลไทม์จาก Firestore สำหรับแต่ละ shipmentId
        for (var shipment in shipmentsreceiverRespone) {
          var shipmentId = shipment.shipmentId;

          FirebaseFirestore.instance
              .collection('shipments')
              .doc(shipmentId.toString())
              .snapshots() // สมัครรับข้อมูลเรียลไทม์
              .listen((snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data();
              log('shipments ID: ${data!['shipment_id'].toString()}');
              log('Receiver ID: ${data!['receiver_id'].toString()}');
              log('Sender ID: ${data['sender_id'].toString()}');
              log('Status: ${data['status'].toString()}');

              // ค้นหา shipment ในรายการและอัปเดตสถานะหรือเพิ่มใหม่
              var existingIndex = shipmentsDetails.indexWhere((element) =>
                  element['receiver_id'] ==
                  data['receiver_id']); // ตรงกับ receiver_id

              if (existingIndex >= 0) {
                // อัปเดตรายการที่มีอยู่
                shipmentsDetails[existingIndex] = data;
              } else {
                // เพิ่มรายการใหม่
                shipmentsDetails.add(data);
              }

              // อัปเดต UI
              setState(() {});
            } else {
              log("Document does not exist");
            }
          });
        }
      } else {
        _showSnackBar('Failed to load shipments');
      }
    } catch (error) {
      log('Error fetching shipments: $error');
      _showSnackBar('Error fetching shipments: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildReceiveSection() {
    // Display a loading indicator while fetching data
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Handle case where no shipments are found
    if (shipmentsreceiverRespone.isEmpty) {
      return Center(child: Text('No deliveries available'));
    }

    // Build the list of deliveries
    return ListView.builder(
      itemCount: shipmentsreceiverRespone.length,
      itemBuilder: (context, index) {
        final delivery = shipmentsreceiverRespone[index];
        final shipmentId = delivery.shipmentId;
        final pickupLocation = delivery.receiverGps;
        final deliveryLocation = delivery.senderGps;

        // ค้นหาข้อมูลสถานะที่ตรงกันจาก shipmentsDetails
        final statusData = shipmentsDetails.firstWhere(
          (element) => element['shipment_id'] == shipmentId,
          orElse: () => {'status': 0}, // ค่าเริ่มต้นถ้าไม่พบ
        );
        final status = statusData['status'];

        return GestureDetector(
          onTap: () {
            // Navigate to MapScreen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  shipmentId: shipmentId,
                  pickupLocation: pickupLocation,
                  deliveryLocation: deliveryLocation,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 160,
            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
            child: Card(
              color: Colors.white,
              elevation: 10,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(delivery.senderImage),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(5, 45, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "ชื่อ: ${delivery.receiverName}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("เบอร์โทร: ${delivery.senderPhone}"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        const SizedBox(height: 50),
        CircleAvatar(
            radius: 80, backgroundImage: NetworkImage(userGetResponsse.image)),
        const SizedBox(height: 30),
        _buildProfileBox([
          _buildListTile(FontAwesomeIcons.userLarge, 'ข้อมูลส่วนตัว', () {}),
          _buildListTile(FontAwesomeIcons.gear, 'เปลี่ยนรหัสผ่าน', () {}),
        ]),
        const SizedBox(height: 5),
        _buildProfileBox([
          _buildListTile(
              FontAwesomeIcons.doorOpen, 'ออกจากระบบ', _showLogoutDialog),
        ]),
      ],
    );
  }

  Widget _buildProfileBox(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการออกจากระบบ'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก',
                    style: TextStyle(color: Colors.blueGrey))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: const Text('ออกจากระบบ',
                  style: TextStyle(color: Color.fromARGB(255, 255, 0, 0))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon,
              size: 30.0, color: isSelected ? Colors.blueGrey : Colors.black),
          onPressed: () => _onIconButtonPressed(index),
        ),
        Text(label,
            style:
                TextStyle(color: isSelected ? Colors.blueGrey : Colors.black)),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
