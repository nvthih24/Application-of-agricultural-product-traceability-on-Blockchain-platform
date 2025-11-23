import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart'; // Import màn hình quét QR cũ của bạn
import 'farm_detail_screen.dart';
import 'profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Màu sắc chủ đạo lấy từ thiết kế của bạn
const Color kPrimaryColor = Color(0xFF00C853); // Xanh lá
const Color kAccentColor = Color(0xFFFF6D00); // Cam đậm (cho nút bấm)
const Color kBackgroundColor = Color(0xFFF5F5F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex =
      0; // Biến để theo dõi tab đang chọn (0: Home, 3: Profile)

  // Danh sách các màn hình tương ứng với các Tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(), // Tab 0: Trang chủ (Code cũ nằm ở đây)
    const Center(child: Text("Đang nâng cấp (Saved)")), // Tab 1
    const Center(child: Text("Đang nâng cấp (Orders)")), // Tab 2
    const ProfileScreen(), // Tab 3: Tài khoản & Đăng nhập (CÁI BẠN CẦN)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Cập nhật tab khi bấm
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Nội dung thay đổi dựa theo tab đang chọn
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          // ▼▼▼ ĐÂY LÀ CHỖ ĐĂNG NHẬP ▼▼▼
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped, // Bắt sự kiện bấm
      ),
    );
  }
}

// ====================
// GIAO DIỆN TRANG CHỦ
// ====================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> _farms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFarms();
  }

  // Hàm gọi API lấy danh sách nông dân
  Future<void> _fetchFarms() async {
    try {
      // Lưu ý: Đây là API công khai, không cần Token
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/farmers'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _farms = data['data']; // Gán dữ liệu vào list
          _isLoading = false;
        });
      } else {
        // Lỗi nhẹ thì cứ cho list rỗng, tắt loading
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.looks_3, color: Colors.white, size: 30),
        ),
        title: const Text(
          "3TML FARM",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER (Giữ nguyên code cũ của ông cho đẹp)
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        // Dùng ảnh thật hoặc ảnh mạng nếu có
                        image: AssetImage('assets/images/banner-2.jpg'),
                        fit: BoxFit.cover,
                        opacity: 0.8,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Minh bạch\ntừ nông trại\nđến bàn ăn.",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. DANH MỤC (Giữ nguyên)
            _buildSectionTitle("Danh mục", () {}),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip("Rau củ", Icons.eco),
                  _buildCategoryChip("Trái cây", Icons.circle),
                  _buildCategoryChip("Gạo", Icons.grass),
                  _buildCategoryChip("Hạt", Icons.lens),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. NÔNG TRẠI NỔI BẬT (DATA THẬT)
            _buildSectionTitle("Nông trại tiêu biểu", () {}),

            // Hiển thị List thật
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : _farms.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Chưa có nông trại nào đăng ký."),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _farms.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      return _buildFarmCard(context, _farms[index]);
                    },
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Widget Tiêu đề
  Widget _buildSectionTitle(String title, VoidCallback onPress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          // GestureDetector(onTap: onPress, child: const Text("Xem tất cả", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // Widget Chip Danh mục
  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Widget Card Nông Trại (ĐÃ SỬA ĐỂ NHẬN DATA THẬT)
  Widget _buildFarmCard(BuildContext context, dynamic farm) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FarmDetailScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh cover (Vì User chưa có chức năng up ảnh bìa, ta dùng ảnh random hoặc mặc định)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/farm_1.jpg', // Dùng ảnh mặc định cho đẹp
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // HIỂN THỊ TÊN THẬT CỦA FARMER
                      Text(
                        farm['fullName'] ?? "Nông trại ẩn danh",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 20,
                      ), // Thêm cái tick xanh cho uy tín
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 5),
                      // HIỂN THỊ ĐỊA CHỈ THẬT
                      Text(
                        farm['address'] ?? "Chưa cập nhật địa chỉ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "SĐT: ${farm['phone']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
