import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'signup_screen.dart';
import 'home_screen.dart';
import 'farmer_main_screen.dart';
import 'transporter_main_screen.dart';
import 'inspector_main_screen.dart';
import 'retailer_main_screen.dart';
import 'forgot_password_screen.dart';

import '../configs/constants.dart';
import '../services/api_service.dart';

const Color kPrimaryColor = Color(0xFF00C853); // Màu xanh chủ đạo

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // IP máy ảo Android
  final String _baseUrl = '${Constants.baseUrl}/auth';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Hàm xử lý đăng nhập (Giữ nguyên logic phân quyền)
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      print("📡 Server Response Code: ${response.statusCode}");
      print(
        "📦 Server Response Body: ${response.body}",
      ); // 🔥 Quan trọng: Xem nó trả về cái gì

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // --- BẮT ĐẦU XỬ LÝ AN TOÀN (SAFE PARSING) ---
        // Dùng tring() hoặc ?? "" để tránh lỗi Null

        final String token = data['token']?.toString() ?? "";

        // Kiểm tra xem có object 'user' không
        final user = data['user'];
        if (user == null) {
          _showMsg("Lỗi: Server không trả về thông tin User", isError: true);
          return;
        }

        final String userId = user['id']?.toString() ?? ""; // 🔥 Nghi phạm số 1
        final String role =
            user['role']?.toString() ?? "farmer"; // Mặc định là farmer nếu lỗi
        final String fullName =
            data['fullName']?.toString() ??
            user['fullName']?.toString() ??
            "Người dùng"; // Tìm cả 2 chỗ
        final String companyName = user['companyName']?.toString() ?? "";

        // Kiểm tra nhanh xem có cái nào bị rỗng không
        if (token.isEmpty || userId.isEmpty) {
          print("❌ LỖI: Token hoặc ID bị rỗng!");
          print("Token: $token");
          print("ID: $userId");
        }

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('name', fullName);
        await prefs.setString('companyName', companyName);
        await prefs.setString('userId', userId);

        // Gửi FCM Token (Chỉ gửi nếu có userId xịn)
        if (userId.isNotEmpty) {
          try {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              print("📲 Đang gửi FCM Token: $fcmToken");
              await saveDeviceToken(userId, fcmToken);
            }
          } catch (e) {
            print("⚠️ Lỗi FCM: $e");
          }
        }

        if (mounted) {
          _showMsg("Đăng nhập thành công!", isError: false);

          Widget nextScreen;
          switch (role) {
            case 'farmer':
              nextScreen = const FarmerMainScreen();
              break;
            case 'transporter':
              nextScreen = const TransporterMainScreen();
              break;
            case 'moderator':
              nextScreen = const InspectorMainScreen();
              break;
            case 'manager':
              nextScreen = const RetailerMainScreen();
              break;
            default:
              nextScreen = const HomeScreen();
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => nextScreen),
            (route) => false,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMsg(errorData['msg'] ?? 'Đăng nhập thất bại', isError: true);
      }
    } catch (e) {
      print("❌ Lỗi Crash App: $e"); // In lỗi ra console để đọc
      _showMsg('Lỗi xử lý dữ liệu: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : kPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar cùng màu xanh
      appBar: AppBar(
        title: const Text("Đăng Nhập"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            // Logo hoặc Icon trang trí
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withOpacity(0.1),
              ),
              child: const Icon(Icons.spa, size: 80, color: kPrimaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chào mừng trở lại!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Đăng nhập để quản lý nông trại của bạn",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Ô nhập Email (Style mới)
            _buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email,
              inputType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Ô nhập Password (Style mới)
            _buildTextField(
              controller: _passwordController,
              label: "Mật khẩu",
              icon: Icons.lock,
              isPassword: true,
            ),

            const SizedBox(height: 10),
            // Quên mật khẩu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Nút Đăng Nhập
            _isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor, // Màu xanh
                        foregroundColor: Colors.white, // Chữ trắng
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Chuyển sang trang Đăng ký
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Chưa có tài khoản? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Đăng ký ngay",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget tái sử dụng để ô nhập liệu đẹp giống trang Đăng ký
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        // Viền khi chưa bấm vào
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        // Viền khi đang bấm vào (Màu xanh)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
