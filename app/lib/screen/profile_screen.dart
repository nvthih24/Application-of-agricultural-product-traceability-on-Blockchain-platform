import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:convert';
import 'dart:io';

import '../configs/constants.dart';

import 'home_screen.dart';
import 'login_screen.dart';

// Màu chủ đạo (Lấy màu xanh lá nông nghiệp)
const Color kPrimaryColor = Color(0xFF2E7D32);
const Color kBackgroundColor = Color(0xFFF5F7FA);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController =
      TextEditingController(); // Dùng chung cho Farm/Company
  final _addressController = TextEditingController();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userRole = "Khách";
  String _rawRole = "";
  String _userAvatar = "";
  bool _isSaving = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 1. API: TẢI THÔNG TIN
  Future<void> _loadUserProfile() async {
    setState(() => _isFetching = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
        _isFetching = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['user'];
        setState(() {
          _isLoggedIn = true;
          _rawRole = data['role'];
          _userRole = _mapRoleName(_rawRole);
          _userAvatar = data['avatar'] ?? "";

          _nameController.text = data['fullName'] ?? "";
          _emailController.text = data['email'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _farmNameController.text = data['companyName'] ?? "";
          _addressController.text = data['address'] ?? "";

          _saveToPrefs(data);
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi load profile: $e");
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  // Helper: Map tên role sang tiếng Việt
  String _mapRoleName(String role) {
    switch (role) {
      case 'farmer':
        return "Chủ Nông Trại";
      case 'transporter':
        return "Nhà Vận Chuyển";
      case 'manager':
        return "Nhà Bán Lẻ";
      case 'moderator':
        return "Kiểm Duyệt Viên";
      default:
        return "Khách";
    }
  }

  Future<void> _saveToPrefs(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user['fullName'] != null)
      await prefs.setString('fullName', user['fullName']);
    if (user['avatar'] != null) await prefs.setString('avatar', user['avatar']);
    if (user['phone'] != null) await prefs.setString('phone', user['phone']);
    if (user['companyName'] != null) {
      await prefs.setString('companyName', user['companyName']);
      await prefs.setString('farmName', user['companyName']);
    }
    if (user['address'] != null)
      await prefs.setString('address', user['address']);
  }

  // 2. API: CẬP NHẬT PROFILE
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập họ tên")));
      return;
    }
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "fullName": _nameController.text,
          "companyName": _farmNameController.text,
          "address": _addressController.text,
        }),
      );
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['user'];
        await _saveToPrefs(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Cập nhật hồ sơ thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          FocusScope.of(context).unfocus(); // Ẩn bàn phím
        }
      } else {
        throw Exception("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi cập nhật profile: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi cập nhật"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 3. API: UPLOAD ẢNH
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/upload/image'),
      );
      final mimeType = lookupMimeType(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⏳ Đang tải ảnh lên...")));
      String? imageUrl = await _uploadImage(File(image.path));
      if (imageUrl != null) {
        await _callUpdateAvatarOnly(imageUrl);
      }
    }
  }

  Future<void> _callUpdateAvatarOnly(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    await http.post(
      Uri.parse('${Constants.baseUrl}/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"avatar": url}),
    );
    await prefs.setString('avatar', url);
    setState(() => _userAvatar = url);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đổi ảnh đại diện thành công!"),
          backgroundColor: Colors.green,
        ),
      );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('name');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }
    if (!_isLoggedIn) return _buildGuestView();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar ẩn để dùng Header custom cho đẹp
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER CONG + AVATAR
            _buildHeader(),

            const SizedBox(height: 60), // Chừa chỗ cho Avatar đè lên
            // 2. FORM NHẬP LIỆU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin cá nhân",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    "Họ và Tên",
                    _nameController,
                    Icons.person,
                    false,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Email",
                    _emailController,
                    Icons.email,
                    true,
                  ), // Readonly
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Số điện thoại",
                    _phoneController,
                    Icons.phone,
                    true,
                  ), // Readonly
                  // PHẦN RIÊNG CHO FARMER / TRANSPORTER
                  if (_rawRole == 'farmer' ||
                      _rawRole == 'transporter' ||
                      _rawRole == 'manager') ...[
                    const SizedBox(height: 25),
                    Text(
                      _rawRole == 'farmer'
                          ? "Thông tin Nông trại"
                          : (_rawRole == 'manager'
                                ? "Thông tin Cửa hàng"
                                : "Thông tin Doanh nghiệp"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _rawRole == 'farmer'
                          ? "Tên Nông Trại"
                          : (_rawRole == 'manager'
                                ? "Tên Cửa Hàng (VD: WinMart)"
                                : "Tên Công Ty"),
                      _farmNameController,
                      Icons.store,
                      false,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Địa chỉ / Vị trí",
                      _addressController,
                      Icons.location_on,
                      false,
                    ),
                  ],

                  const SizedBox(height: 30),

                  // 3. LIÊN KẾT VÍ (CARD RIÊNG)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.orange,
                        ),
                      ),
                      title: const Text(
                        "Ví Blockchain",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text("Liên kết ví để nhận thanh toán"),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: _showWalletDialog,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. NÚT LƯU
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "LƯU THAY ĐỔI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "Phiên bản 1.0.0 - 3TML Team",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON (WIDGETS) ---

  // 1. HEADER CONG
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        Positioned(
          top: 80,
          child: Column(
            children: [
              const Text(
                "Hồ Sơ Của Tôi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userRole.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // AVATAR
        Positioned(
          bottom: -50,
          child: GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _userAvatar.isNotEmpty
                        ? NetworkImage(_userAvatar)
                        : const AssetImage('assets/images/farm_1.jpg')
                              as ImageProvider,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. TEXT FIELD CUSTOM
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isReadOnly,
  ) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      style: TextStyle(color: isReadOnly ? Colors.grey[700] : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : kPrimaryColor),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  // --- DIALOGS (Giữ nguyên logic cũ) ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  void _showWalletDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ví Blockchain"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Địa chỉ ví (0x...)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tính năng đang phát triển")),
              );
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Icon minh họa
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .lock_person_outlined, // Hoặc Icons.account_circle_outlined
                  size: 80,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 30),

              // 2. Lời mời gọi
              const Text(
                "Bạn chưa đăng nhập",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Đăng nhập ngay để quản lý nông trại, theo dõi vận chuyển và kết nối với khách hàng.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 40),

              // 3. Nút Đăng nhập to đẹp
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ).then(
                      (_) => _loadUserProfile(),
                    ); // Quay lại thì load lại data
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: kPrimaryColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    "ĐĂNG NHẬP / ĐĂNG KÝ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
