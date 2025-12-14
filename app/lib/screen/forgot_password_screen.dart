import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import '../configs/constants.dart';

const Color kPrimaryColor = Color(0xFF00C853);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false; // Đã gửi OTP chưa
  bool _otpVerified = false; // OTP đã được xác minh chưa

  final String _baseUrl = '${Constants.baseUrl}/forgot-password';

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar("Vui lòng nhập email hợp lệ!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => _otpSent = true);
        _showSnackBar("Đã gửi mã OTP đến email của bạn!", Colors.green);
      } else {
        _showSnackBar(data['message'] ?? "Gửi OTP thất bại", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showSnackBar("Vui lòng nhập mã OTP 6 chữ số", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['verified'] == true) {
        setState(() => _otpVerified = true);
        _showSnackBar("Xác minh thành công!", Colors.green);
      } else {
        _showSnackBar(data['message'] ?? "Mã OTP không đúng", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _newPasswordController.text.length < 6) {
      _showSnackBar("Mật khẩu phải ít nhất 6 ký tự", Colors.red);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          "Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại",
          Colors.green,
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // Quay lại màn hình Login
        });
      } else {
        _showSnackBar(
          data['message'] ?? "Đặt lại mật khẩu thất bại",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quên mật khẩu"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(
              Icons.lock_reset,
              size: 90,
              color: kPrimaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            const Text(
              "Đặt lại mật khẩu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Nhập email của bạn để nhận mã xác nhận",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email
            _buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email,
              enabled: !_otpSent, // Không cho sửa email sau khi gửi OTP
            ),
            const SizedBox(height: 20),

            // OTP
            if (_otpSent) ...[
              _buildTextField(
                controller: _otpController,
                label: "Mã OTP (6 chữ số)",
                icon: Icons.sms,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
            ],

            // Mật khẩu mới
            if (_otpVerified) ...[
              _buildTextField(
                controller: _newPasswordController,
                label: "Mật khẩu mới",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                label: "Xác nhận mật khẩu",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),
            ],

            // Nút hành động
            _isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (!_otpSent) {
                          _sendOtp();
                        } else if (_otpSent && !_otpVerified) {
                          _verifyOtp();
                        } else if (_otpVerified) {
                          _resetPassword();
                        }
                      },
                      child: Text(
                        _otpVerified
                            ? "ĐẶT LẠI MẬT KHẨU"
                            : _otpSent
                            ? "XÁC NHẬN OTP"
                            : "GỬI MÃ OTP",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Nút gửi lại OTP
            if (_otpSent && !_otpVerified)
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: const Text(
                  "Gửi lại mã OTP",
                  style: TextStyle(color: kPrimaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }
}
