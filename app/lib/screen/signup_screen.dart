import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../configs/constants.dart';

const Color kPrimaryColor = Color(0xFF00C853); // Màu xanh chủ đạo

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final String _baseUrl = '${Constants.baseUrl}/auth';

  // Controllers quản lý nhập liệu
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 🔥 1. Thêm Controller cho Mã Bí Mật
  final _secretKeyController = TextEditingController();

  // Vai trò mặc định là 'farmer' (Nông dân)
  String _selectedRole = 'farmer';
  final Map<String, String> _roles = {
    'farmer': 'Nông Dân',
    'transporter': 'Nhà Vận Chuyển',
    'moderator': 'Kiểm Duyệt Viên',
    'manager': 'Nhà Bán Lẻ',
  };

  bool _isLoading = false;

  Future<void> _register() async {
    // Validate cơ bản
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMsg("Mật khẩu xác nhận không khớp!", isError: true);
      return;
    }

    // Validate Secret Key (Không được để trống)
    if (_secretKeyController.text.trim().isEmpty) {
      _showMsg(
        "Vui lòng nhập mã xác thực cho vai trò ${_roles[_selectedRole]}",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('$_baseUrl/register');

    try {
      print("Đang gửi đăng ký...");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullNameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
          'role': _selectedRole,
          // 🔥 2. Gửi secretKey lên Server
          'secretKey': _secretKeyController.text.trim(),
        }),
      );

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Đăng ký thành công
        _showMsg("Đăng ký thành công! Vui lòng đăng nhập.", isError: false);

        // Đợi 1.5 giây rồi chuyển về màn hình Login
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context); // Quay lại trang Login
          }
        });
      } else {
        // Lỗi từ Backend (ví dụ: Sai mã xác thực, Email trùng)
        final data = jsonDecode(response.body);
        _showMsg(data['msg'] ?? "Đăng ký thất bại", isError: true);
      }
    } catch (e) {
      _showMsg("Lỗi kết nối: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text("Tạo tài khoản"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Tham gia mạng lưới nông sản sạch",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Các ô nhập liệu
            _buildTextField(_fullNameController, "Họ và tên", Icons.person),
            const SizedBox(height: 15),
            _buildTextField(
              _phoneController,
              "Số điện thoại",
              Icons.phone,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _emailController,
              "Email",
              Icons.email,
              inputType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            _buildTextField(_addressController, "Địa chỉ", Icons.location_on),
            const SizedBox(height: 15),

            // Chọn Vai Trò (Quan trọng)
            DropdownButtonFormField<String>(
              value: _selectedRole,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Vai trò của bạn",
                prefixIcon: const Icon(Icons.work, color: kPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 15,
                ),
              ),
              items: _roles.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                  // 🔥 3. Xóa Key cũ khi đổi Role để người dùng nhập lại
                  _secretKeyController.clear();
                });
              },
            ),

            const SizedBox(height: 15),

            // 🔥 4. Ô nhập MÃ BÍ MẬT (SECRET KEY) - Mới thêm vào
            TextField(
              controller: _secretKeyController,
              decoration: InputDecoration(
                labelText: "Mã xác thực cho ${_roles[_selectedRole]}",
                hintText: "Nhập mã do quản lý cung cấp",
                prefixIcon: const Icon(
                  Icons.vpn_key,
                  color: Colors.orange,
                ), // Icon chìa khóa
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                filled: true,
                fillColor: Colors.orange.withOpacity(
                  0.08,
                ), // Màu nền nhẹ cho nổi bật
              ),
            ),

            const SizedBox(height: 15),
            _buildTextField(
              _passwordController,
              "Mật khẩu",
              Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _confirmPasswordController,
              "Xác nhận mật khẩu",
              Icons.lock_outline,
              isPassword: true,
            ),

            const SizedBox(height: 40),

            // Nút Đăng Ký
            _isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ĐĂNG KÝ NGAY",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }
}
