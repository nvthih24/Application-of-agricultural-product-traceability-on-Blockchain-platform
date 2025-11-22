import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
// import 'transporter_main_screen.dart';
import 'farmer_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Giống như API base URL của bạn
  final String _baseUrl = 'http://10.0.2.2:5000/api/auth';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    // 1. Kiểm tra xem backend của bạn dùng /login hay /signin nhé!
    // Mình sẽ đoán là /login
    final Uri loginUrl = Uri.parse('$_baseUrl/login');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        // 1. Lấy Role từ phản hồi
        final String role = data['user']['role'];

        // 2. Lưu Token và Role vào bộ nhớ máy (để lần sau mở app tự vào đúng chỗ)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);

        // 3. Điều hướng dựa trên Role (Logic quan trọng nhất)
        if (mounted) {
          Widget nextScreen;
          switch (role) {
            case 'farmer':
              nextScreen =
                  const FarmerMainScreen(); // Giao diện riêng cho Nông dân
              break;
            case 'transporter':
            // case 'manager': // Giả sử manager cũng làm vận chuyển
            //   nextScreen =
            //       const TransporterMainScreen(); // Giao diện riêng cho Vận chuyển
            //   break;
            default:
              nextScreen = const HomeScreen(); // Giao diện Người tiêu dùng
          }

          // Chuyển màn hình và xóa hết lịch sử lùi lại (để không back về login được)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => nextScreen),
            (route) => false,
          );
        }
      } else {
        // Hiển thị lỗi (giống toast.error)
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      _showErrorDialog('Lỗi kết nối: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Đăng Nhập'),
                  ),
          ],
        ),
      ),
    );
  }
}
