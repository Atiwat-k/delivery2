import 'dart:convert';
import 'package:delivery/config/config.dart';

import 'package:delivery/models/response/user_login_PostRes.dart';
import 'package:delivery/register_rider.dart';
import 'package:delivery/register_user.dart';
import 'package:delivery/user/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'models/request/user_login_post_req.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = ""; // ตัวแปรสำหรับเก็บข้อความผิดพลาด
  String url = '';

  void initState() {
    // TODO: implement initState
    super.initState();
    //Configguration config = Configguration();

    Configguration.getConfig().then(
      (value) {
        log(value['apiEndpoint']);
        setState(() {
          url = value['apiEndpoint'];
        });
      },
    ).catchError((err) {
      log(err.toString());
    });
  }

  void user_login() {
    UserLogin req = UserLogin(
        phone: phoneController.text,
        password: passwordController.text); // ใช้ passwordController
    http
        .post(
      Uri.parse("$url/user/login"), // แก้ไขเป็น url ที่ได้จาก config
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: userLoginToJson(req),
    )
        .then((value) {
      log(value.body);
      if (value.statusCode == 200) {
        UserLoginPostRes userLoginPostRes =
            userLoginPostResFromJson(value.body);
        log(userLoginPostRes.user.name);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserPage(uid: userLoginPostRes.user.uid),
          ),
        );
      } else {
        // แสดง SnackBar เมื่อไม่พบผู้ใช้หรือรหัสผ่านไม่ถูกต้อง
        String message =
            jsonDecode(value.body)["message"] ?? "ไม่ทราบข้อผิดพลาด";
        _showSnackBar(message);
      }
    }).catchError((error) {
      log('Error: $error');
      _showSnackBar("เกิดข้อผิดพลาดในการเข้าสู่ระบบ");
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  void rider_login() {}

  void _showLoginTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "เลือกประเภทการเข้าสู่ระบบ",
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAccountTypeButton("ผู้ใช้", Colors.blueGrey, () {
                  Navigator.of(context).pop();
                  user_login(); // เรียกใช้ API สำหรับผู้ใช้
                }),
                _buildAccountTypeButton("ไรเดอร์", Colors.green, () {
                  Navigator.of(context).pop();
                  rider_login(); // เรียกใช้ API สำหรับไรเดอร์
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 70.0),
          child: Column(
            children: [
              _buildLogo(),
              const SizedBox(height: 30),
              _buildTitle("Login"),
              const SizedBox(height: 10),
              _buildTextField("เบอร์โทร", "กรุณากรอกเบอร์โทร",
                  controller: phoneController,
                  isPassword: false,
                  isPhone: true),
              const SizedBox(height: 10),
              _buildTextField("รหัสผ่าน", "กรุณากรอกรหัสผ่าน",
                  controller: passwordController,
                  isPassword: true,
                  isPhone: false),
              if (errorMessage.isNotEmpty) // แสดงข้อความผิดพลาดหากมี
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _buildForgotPasswordButton(),
              const SizedBox(height: 10),
              _buildElevatedButton("เข้าสู่ระบบ", () {
                _showLoginTypeDialog(
                    context); // เปิดหน้าเลือกประเภทการเข้าสู่ระบบ
              }),
              const SizedBox(height: 20),
              _buildRegisterButton(
                  "สมัครสมาชิก", () => _showAccountTypeDialog(context)),
              const SizedBox(height: 40),
              _buildFooterLogo(),
            ],
          ),
        ),
      ),
    );
  }

  // Functions to build UI elements (similar to your original code)

  Widget _buildLogo() {
    return GestureDetector(
      onDoubleTap: () => log("image double tap"),
      child: Image.asset(
        'assets/images/turbo.png',
        width: 340.0,
        height: 150.0,
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 40.0,
        fontWeight: FontWeight.w800,
        color: Color.fromARGB(255, 67, 112, 126),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      {required TextEditingController controller,
      required bool isPassword,
      required bool isPhone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: 300.0,
          height: 50,
          child: TextField(
            controller: controller, // เชื่อมต่อ controller ที่นี่
            obscureText: isPassword,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters:
                isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide.none,
              ),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => log("Forgot password pressed"),
          child: const Text(
            "ลืมรหัสผ่าน?",
            style: TextStyle(fontSize: 14.0, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildElevatedButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 300.0,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 67, 112, 126),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 300.0,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
              color: Color.fromARGB(255, 67, 112, 126), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18.0,
            color: Color.fromARGB(255, 67, 112, 126),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLogo() {
    return Image.asset(
      'assets/images/tt.png',
      width: 340.0,
      height: 40.0,
    );
  }

  void _showAccountTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "เลือกประเภท",
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAccountTypeButton("ผู้ใช้", Colors.blueGrey, () {
                  Navigator.of(context).pop();
                  log("User selected");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterUserPage()),
                  );
                }),
                _buildAccountTypeButton("ไรเดอร์", Colors.green, () {
                  Navigator.of(context).pop();
                  log("Rider selected");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Register_RiderPage()),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountTypeButton(
      String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 110.0, // กำหนดความกว้างของปุ่ม
      height: 50.0, // กำหนดความสูงของปุ่ม
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
