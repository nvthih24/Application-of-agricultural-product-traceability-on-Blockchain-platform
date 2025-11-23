import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

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

    // Lưu ý: Để hiện tên thật, lúc Login bạn cần lưu thêm Name/Email vào Prefs
    // Hoặc gọi API /me để lấy. Ở đây mình tạm giả lập dựa trên Role.

    setState(() {
      _isLoggedIn = token != null;
      if (_isLoggedIn) {
        _userRole = role == 'farmer'
            ? "Chủ Nông Trại"
            : role == 'transporter'
            ? "Nhà Vận Chuyển"
            : "Người Tiêu Dùng";
        _userName = "Nguyễn Văn A"; // Sau này lấy từ API
        _userEmail = "user@gmail.com"; // Sau này lấy từ API
      }
    });
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

    // Hoặc chuyển hẳn về màn hình Login nếu muốn
    if (mounted) {
      // Thay vì đến LoginScreen, hãy đưa họ về HomeScreen
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

  // Hàm gọi API update ví
  Future<void> _updateWallet(String address) async {
    if (address.isEmpty || !address.startsWith("0x") || address.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Địa chỉ ví không hợp lệ!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ... Gọi API http.post('/api/auth/update-wallet') ...
    // Nếu thành công thì setState lại biến _userWalletAddress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Liên kết ví thành công!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu chưa đăng nhập -> Hiện giao diện Khách
    if (!_isLoggedIn) {
      return _buildGuestView();
    }

    // Nếu đã đăng nhập -> Hiện giao diện Profile xịn
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profile (Màu xanh cong cong)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, // Avatar nằm đè lên vạch
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/images/farm_1.jpg',
                      ), // Ảnh đại diện giả
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

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
            _buildProfileOption(Icons.lock_outline, "Đổi mật khẩu", () {}),
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
