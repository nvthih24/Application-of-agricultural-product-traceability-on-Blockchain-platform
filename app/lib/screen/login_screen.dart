import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

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

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPass = prefs.getString('saved_password');

    // Nếu có thông tin cũ -> Điền sẵn vào ô
    if (savedEmail != null && savedPass != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPass;
      });

      // Đợi 0.5s cho UI ổn định rồi bật quét vân tay luôn
      Future.delayed(const Duration(milliseconds: 500), () {
        _authenticateAndAutoLogin();
      });
    }
  }

  // Hàm quét vân tay ĐẶC BIỆT cho trường hợp này
  Future<void> _authenticateAndAutoLogin() async {
    // Kiểm tra thiết bị...
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    if (!canAuthenticateWithBiometrics) return;

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Chào ${_emailController.text}! Quét vân tay để đăng nhập lại.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // 🔥 QUÉT ĐÚNG -> GỌI LOGIN LUÔN (Không cần bấm nút)
        _showMsg("Xác thực thành công! Đang đăng nhập...", isError: false);
        _login();
      }
    } catch (e) {
      print("Lỗi vân tay: $e");
    }
  }

  // Hàm xử lý đăng nhập (Giữ nguyên logic phân quyền)
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token']?.toString() ?? "";
        final user = data['user'];

        if (user == null) {
          _showMsg("Lỗi: Server không trả về thông tin User", isError: true);
          return;
        }

        final String userId = user['id']?.toString() ?? "";
        final String role = user['role']?.toString() ?? "farmer";
        final String fullName =
            data['fullName']?.toString() ??
            user['fullName']?.toString() ??
            "Người dùng";
        final String companyName = user['companyName']?.toString() ?? "";

        // Lưu thông tin
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('name', fullName);
        await prefs.setString('companyName', companyName);
        await prefs.setString('userId', userId);
        await prefs.setString('saved_email', _emailController.text);
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('is_staff', true);

        // Gửi FCM Token
        if (userId.isNotEmpty) {
          try {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) await saveDeviceToken(userId, fcmToken);
          } catch (e) {
            print("⚠️ Lỗi FCM: $e");
          }
        }

        if (mounted) {
          _showMsg("Đăng nhập thành công!", isError: false);
          // 🔥 Gọi hàm điều hướng chung (Thay cho đoạn switch case dài dòng cũ)
          _navigateBasedOnRole(role);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMsg(errorData['msg'] ?? 'Đăng nhập thất bại', isError: true);
      }
    } catch (e) {
      _showMsg('Lỗi xử lý dữ liệu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 HÀM XỬ LÝ VÂN TAY
  Future<void> _authenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    // 1. Kiểm tra xem đã từng đăng nhập chưa
    if (token == null || token.isEmpty || role == null) {
      _showMsg("Vui lòng đăng nhập bằng mật khẩu lần đầu tiên", isError: true);
      return;
    }

    // 2. Kiểm tra thiết bị có hỗ trợ không
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } catch (e) {
      print("Lỗi check vân tay: $e");
    }

    if (!canCheckBiometrics) {
      _showMsg("Thiết bị không hỗ trợ vân tay/FaceID", isError: true);
      return;
    }

    // 3. Tiến hành quét
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Quét vân tay để đăng nhập vào AgriTrace',
        options: const AuthenticationOptions(
          stickyAuth: true, // Giữ luôn active khi app bị switch
          biometricOnly: true, // Chỉ dùng sinh trắc học
        ),
      );

      // 4. Nếu khớp -> Vào App luôn
      if (didAuthenticate) {
        _showMsg("Xác thực thành công!", isError: false);
        _navigateBasedOnRole(role); // Hàm điều hướng cũ
      }
    } on PlatformException catch (e) {
      print("Lỗi auth: $e");
      _showMsg("Lỗi xác thực: ${e.message}", isError: true);
    }
  }

  // Tách hàm điều hướng ra cho gọn (để dùng chung cho cả Login thường và Vân tay)
  void _navigateBasedOnRole(String role) {
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

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(
                  Icons.fingerprint,
                  size: 28,
                  color: kPrimaryColor,
                ),
                label: const Text(
                  "Đăng nhập nhanh bằng Vân tay",
                  style: TextStyle(
                    fontSize: 16,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
