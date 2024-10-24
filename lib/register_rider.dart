import 'dart:convert';
import 'dart:io';
//import 'package:delivery/config/config.dart';
import 'package:delivery/config/internal_config.dart';
import 'package:delivery/login.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:latlong2/latlong.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
//import 'gps.dart';
//import 'map_page.dart';
import 'package:http_parser/http_parser.dart';

class Register_RiderPage extends StatefulWidget {
  const Register_RiderPage({Key? key}) : super(key: key);

  @override
  _RegisterRiderPageState createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<Register_RiderPage> {
  XFile? _selectedImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _vehicleRegistrationController =
      TextEditingController();
  bool _isLoading = false; // Variable to indicate loading state

  Future<void> _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    // if (_phoneController.text.length != 10) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('ใส่เบอร์ให้ครบ 10 ตัวด้วยเนาะ')),
    //   );
    //   return;
    // }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกภาพโปรไฟล์')),
      );
      return;
    }

    if (_passwordController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่รหัสผ่าน')),
      );
      return;
    }
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_ENDPOINT/rider/add-rider'), // Use baseUrl from config
      );

      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['vehicleRegistration'] =
          _vehicleRegistrationController.text;

      // Ensure only image formats are allowed
      if (_selectedImage != null) {
        final fileExtension =
            _selectedImage!.path.split('.').last.toLowerCase();
        if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
          var imageFile = await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
            contentType: MediaType('image', fileExtension),
          );
          request.files.add(imageFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('โปรดเลือกไฟล์รูปภาพที่ถูกต้อง (PNG, JPG, JPEG)')),
          );
          return;
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        // Show custom success dialog
        _showSuccessDialog();
      } else {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        // Debug: Print the entire response to see its structure
        print('Error response: $jsonResponse');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'สมัครสมาชิกไม่สำเร็จ: ${jsonResponse['error'] ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Row(
              children: [
                Text(
                  "สำเร็จ",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          content: const Row(
            children: [
              Text(
                "สมัครสมาชิกสำเร็จ",
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "ปิด",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
      appBar: AppBar(
        title: const Text("สมัครสมาชิก"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _selectedImage != null
                      ? FileImage(File(_selectedImage!.path))
                      : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildLabelText("ชื่อ"),
              _buildTextField(controller: _nameController),
              _buildLabelText("เบอร์โทร"),
              _buildTextField(controller: _phoneController),
              _buildLabelText("รหัสผ่าน"),
              _buildTextField(
                  controller: _passwordController, isPassword: true),
              _buildLabelText("ยืนยันรหัสผ่าน"),
              _buildTextField(
                  controller: _confirmPasswordController, isPassword: true),
              _buildLabelText("ทะเบียนรถ"),
              _buildTextField(controller: _vehicleRegistrationController),
              const SizedBox(height: 20),
              if (_isLoading) // Show CircularProgressIndicator if loading
                CircularProgressIndicator()
              else
                _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: SizedBox(
        height: 45,
        width: double.infinity,
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 216, 216, 216),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 5),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          minimumSize: const Size(double.infinity, 45),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("สมัครสมาชิก",
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
}
