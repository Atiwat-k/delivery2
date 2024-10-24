import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FirebasePage extends StatefulWidget {
  const FirebasePage({super.key});

  @override
  State<FirebasePage> createState() => _FirebasePageState();
}

class _FirebasePageState extends State<FirebasePage> {
  TextEditingController docCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController messageCtl = TextEditingController();
  String m = "";
  var db = FirebaseFirestore.instance;
  late StreamSubscription listener;

  @override
  void initState() {
    super.initState();
    // ไม่ควรเรียก startRealtimeGet() ที่นี่ เพราะ docCtl.text อาจจะยังว่างเปล่า
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const Text('Document'),
          TextField(
            controller: docCtl,
          ),
          const Text('Name'),
          TextField(
            controller: nameCtl,
          ),
          const Text('Message'),
          TextField(
            controller: messageCtl,
          ),
          FilledButton(
              onPressed: () {
                var data = {
                  'name': nameCtl.text,
                  'message': messageCtl.text,
                  'createAt': DateTime.now(), // ใช้ DateTime.now() แทน DateTime.timestamp()
                };

                db.collection('status').doc(docCtl.text).set(data);
              },
              child: const Text('Add Data')),
          const SizedBox(height: 20),
          Text(m), // จะแสดงค่าของ m ที่เปลี่ยนแปลง
          const SizedBox(height: 20),
          FilledButton(onPressed: readData, child: const Text("Read Data")),
          FilledButton(onPressed: queryData, child: const Text("Query Data")),
          FilledButton(
              onPressed: () {
                // เรียก startRealtimeGet เมื่อแน่ใจว่ามีการป้อนค่า docCtl
                if (docCtl.text.isNotEmpty) {
                  startRealtimeGet();
                } else {
                  Get.snackbar("Error", "Document field is empty");
                }
              },
              child: const Text('Start Real-time Get')),
          FilledButton(
              onPressed: stopRealTime, child: const Text('Stop Real-time Get'))
        ],
      ),
    );
  }

  void readData() async {
    var result = await db.collection('status').doc(docCtl.text).get();
    var data = result.data();
    log(data!['message']);

    log((data['createAt'] as Timestamp).millisecondsSinceEpoch.toString());

    setState(() {
      m = data['message']; // อัปเดตค่า m และรีเฟรช UI
    });
  }

  void queryData() async {
    var inboxRef = db.collection("inbox");
    var query = inboxRef.where("name", isEqualTo: nameCtl.text);
    var result = await query.get();
    if (result.docs.isNotEmpty) {
      log(result.docs.first.data()['message']);
    }
  }

  void startRealtimeGet() {
    final docRef = db.collection("status").doc(docCtl.text);
    listener = docRef.snapshots().listen(
      (event) {
        var data = event.data();
        setState(() {
          m = data!['message']; // อัปเดตค่า m ทันทีเมื่อมีการเปลี่ยนแปลงข้อมูล
        });
        Get.snackbar(data!['name'].toString(), data['message'].toString());
        log("current data: ${event.data()}");
      },
      onError: (error) => log("Listen failed: $error"),
    );
  }

  void stopRealTime() {
    listener.cancel(); // หยุดการรับข้อมูลแบบเรียลไทม์
  }
}

