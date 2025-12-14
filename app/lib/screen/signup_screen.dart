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

  String _selectedRole = 'consumer'; // Vai trò mặc định
  final Map<String, String> _roles = {
    'consumer': 'Khách Hàng',
    'farmer': 'Nông Dân',
    'transporter': 'Nhà Vận Chuyển',
    'moderator': 'Kiểm Duyệt Viên',
    'manager': 'Nhà Bán Lẻ',
  };

  bool _isLoading = false;

  bool get _isSecretKeyRequired => _selectedRole != 'consumer';

  Future<void> _register() async {
    // Validate cơ bản
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMsg("Mật khẩu xác nhận không khớp!", isError: true);
      return;
    }

    // Validate Secret Key nếu vai trò không phải là consumer
    if (_isSecretKeyRequired && _secretKeyController.text.trim().isEmpty) {
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
      final bodyData = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'password': _passwordController.text,
        'confirmPassword': _confirmPasswordController.text,
        'role': _selectedRole,
        'secretKey': _secretKeyController.text.trim(),
      };

      if (_isSecretKeyRequired) {
        bodyData['secretKey'] = _secretKeyController.text.trim();
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
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
        behavior: SnackBarBehavior.floating,
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông tin cá nhân",
              style: TextStyle(
                fontSize: 18,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

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

            const SizedBox(height: 30),
            const Text(
              "Phân quyền hệ thống",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down_circle,
                    color: kPrimaryColor,
                  ),
                  items: _roles.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(
                            entry.key == 'consumer'
                                ? Icons.shopping_cart
                                : Icons.verified_user,
                            color: entry.key == 'consumer'
                                ? Colors.grey
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      _secretKeyController.clear(); // Xóa key cũ khi đổi role
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            AnimatedCrossFade(
              firstChild: Container(), // Trạng thái ẩn (cho Consumer)
              secondChild: Column(
                children: [
                  TextField(
                    controller: _secretKeyController,
                    decoration: InputDecoration(
                      labelText: "Nhập Mã Bí Mật (${_roles[_selectedRole]})",
                      hintText: "Mã do quản trị viên cung cấp...",
                      prefixIcon: const Icon(
                        Icons.vpn_key,
                        color: Colors.orange,
                      ),
                      filled: true,
                      fillColor: Colors.orange.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.deepOrange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "* Mã này bắt buộc để xác minh danh tính đối tác",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              crossFadeState: _isSecretKeyRequired
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(
                milliseconds: 300,
              ), // Thời gian trượt hiệu ứng
            ),

            const SizedBox(height: 30),

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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "ĐĂNG KÝ NGAY",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 30),
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
