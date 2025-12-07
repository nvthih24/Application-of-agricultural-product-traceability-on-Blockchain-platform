import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

// Màu chủ đạo
const Color kPrimaryColor = Color(0xFF00C853);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _userRole = "Khách";
  String _userName = "Người dùng";
  String _userEmail = "Chưa đăng nhập";
  String _companyName = "";
  bool _isTransporter = false;
  String _userAvatar = "";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Kiểm tra xem trong máy có lưu token không
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final company = prefs.getString('companyName'); // Lấy công ty từ bộ nhớ
    final avatar = prefs.getString('avatar');

    // Lưu ý: Để hiện tên thật, lúc Login bạn cần lưu thêm Name/Email vào Prefs
    // Hoặc gọi API /me để lấy. Ở đây mình tạm giả lập dựa trên Role.

    setState(() {
      _isLoggedIn = (token != null && token.isNotEmpty);
      if (_isLoggedIn) {
        _userRole = role == 'farmer'
            ? "Chủ Nông Trại"
            : role == 'transporter'
            ? "Nhà Vận Chuyển"
            : role == 'manager'
            ? "Nhà Bán Lẻ"
            : "Kiểm Duyệt Viên";
        _isTransporter = role == 'transporter';
        _userName = name ?? "Người dùng";
        _userEmail = email ?? "Chưa cập nhật";
        _companyName = company ?? "Chưa cập nhật";
        _userAvatar = avatar ?? "";
      } else {
        _userRole = "Khách";
        _userName = "Người dùng";
      }
    });
  }

  // HÀM CẬP NHẬT CÔNG TY (Gọi API Backend)
  Future<void> _updateCompanyDialog() async {
    final controller = TextEditingController(
      text: _companyName == "Chưa cập nhật" ? "" : _companyName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật đơn vị vận chuyển"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên công ty / Nhà xe",
            hintText: "VD: 3TML Logistics",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _callUpdateProfileAPI(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _callUpdateProfileAPI(String newCompany) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"companyName": newCompany}),
      );

      if (response.statusCode == 200) {
        // Lưu vào máy
        await prefs.setString('companyName', newCompany);

        // Cập nhật giao diện ngay lập tức
        setState(() {
          _companyName = newCompany;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật thành công!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Nếu lỗi thì hiện thông báo đỏ lên màn hình luôn
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi Server: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("--> LỖI KẾT NỐI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm Đăng xuất
  // --- THÊM HÀM NÀY VÀO ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Hủy
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
                _logout(); // Gọi hàm đăng xuất thực sự
              },
              child: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa sạch token

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Xóa sạch lịch sử cũ
      );
    }
  }

  // Hàm hiển thị Dialog nhập ví
  void _showWalletDialog() {
    final TextEditingController walletController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liên kết Ví Blockchain"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nhập địa chỉ ví của bạn (Metamask/TrustWallet) để nhận thanh toán sau này.",
            ),
            const SizedBox(height: 10),
            TextField(
              controller: walletController,
              decoration: const InputDecoration(
                labelText: "Địa chỉ ví (0x...)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              // GỌI API LƯU VÍ
              await _updateWallet(walletController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "Liên kết",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm gọi API update ví (BẢN HOÀN CHỈNH)
  Future<void> _updateWallet(String address) async {
    // 1. Validate cơ bản
    if (address.isEmpty || !address.startsWith("0x") || address.length != 42) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Địa chỉ ví không hợp lệ! (Phải bắt đầu bằng 0x và dài 42 ký tự)",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Lấy token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // 3. Gọi API
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/update-wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'walletAddress': address}),
      );

      // 4. Xử lý kết quả
      if (response.statusCode == 200) {
        // Thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Liên kết ví thành công!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        // (Tùy chọn) Lưu ví vào prefs nếu muốn dùng lại ở chỗ khác
        await prefs.setString('walletAddress', address);
      } else {
        // Thất bại (Ví dụ: Ví đã được dùng bởi user khác)
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Lỗi: ${errorData['error'] ?? 'Cập nhật thất bại'}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Lỗi mạng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm upload ảnh lên Server
  Future<String?> _uploadImage(File imageFile) async {
    try {
      // URL upload ảnh của ông (check lại IP nếu dùng máy thật)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/upload/image'),
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
      return null;
    } catch (e) {
      print("Upload lỗi: $e");
      return null;
    }
  }

  // Hàm chọn ảnh và cập nhật Avatar
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đang tải ảnh lên...")));

      // 1. Upload lấy link
      String? imageUrl = await _uploadImage(File(image.path));

      if (imageUrl != null) {
        // 2. Gọi API cập nhật Profile với link ảnh mới
        await _callUpdateAvatarAPI(imageUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi upload ảnh"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Gọi API update profile chỉ để update avatar
  Future<void> _callUpdateAvatarAPI(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"avatar": url}), // Chỉ gửi avatar
      );

      if (response.statusCode == 200) {
        await prefs.setString('avatar', url); // Lưu vào máy
        setState(() {
          _userAvatar = url; // Cập nhật UI ngay
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đổi ảnh đại diện thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildGuestView();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profile (Màu xanh cong cong)
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar, // <--- BẤM VÀO ĐỂ ĐỔI ẢNH
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      // Nếu có avatar thì hiện, không thì hiện ảnh mặc định
                      backgroundImage: (_userAvatar.isNotEmpty)
                          ? NetworkImage(_userAvatar) as ImageProvider
                          : const AssetImage('assets/images/farm_1.jpg'),
                    ),
                  ),
                ),
                // Thêm icon máy ảnh nhỏ nhỏ bên cạnh cho người ta biết là bấm được
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SECTION: THÔNG TIN VẬN CHUYỂN (Chỉ hiện cho Transporter)
            if (_isTransporter)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.blue),
                  title: const Text("Công ty / Đơn vị"),
                  subtitle: Text(
                    _companyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: _updateCompanyDialog,
                ),
              ),

            const SizedBox(height: 20),
            // Tên và Vai trò
            Text(
              _userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(_userEmail, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor),
              ),
              child: Text(
                _userRole,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. Menu Cài đặt
            _buildSectionHeader("Cài đặt tài khoản"),
            _buildProfileOption(
              Icons.person_outline,
              "Chỉnh sửa thông tin cá nhân",
              () {},
            ),

            _buildProfileOption(
              Icons.account_balance_wallet_outlined,
              "Ví Blockchain",
              () {
                _showWalletDialog();
              },
            ), // Mục quan trọng

            const SizedBox(height: 20),
            _buildSectionHeader("Ứng dụng"),
            _buildProfileOption(Icons.language, "Ngôn ngữ", () {}),
            _buildProfileOption(Icons.help_outline, "Trung tâm hỗ trợ", () {}),
            _buildProfileOption(Icons.info_outline, "Về chúng tôi", () {}),

            const SizedBox(height: 30),

            // Nút Đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Đăng xuất",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  // Widget giao diện cho khách chưa đăng nhập
  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              "Bạn chưa đăng nhập",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Đăng nhập để quản lý nông trại, vận chuyển và lưu sản phẩm yêu thích.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Chuyển sang màn hình Login và chờ kết quả trả về
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  ).then(
                    (_) => _checkLoginStatus(),
                  ); // Load lại trạng thái khi quay về
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ĐĂNG NHẬP / ĐĂNG KÝ",
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
