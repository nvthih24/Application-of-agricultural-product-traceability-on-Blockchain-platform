import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart'; // Import màn hình quét QR cũ của bạn
import 'farm_detail_screen.dart';
import 'login_screen.dart';

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
    const Center(child: Text("Màn hình Yêu thích (Saved)")), // Tab 1
    const Center(child: Text("Màn hình Đơn hàng (Orders)")), // Tab 2
    const ProfileContent(), // Tab 3: Tài khoản & Đăng nhập (CÁI BẠN CẦN)
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

// ==========================================
// PHẦN 1: GIAO DIỆN PROFILE (Nơi chứa nút Đăng nhập)
// ==========================================
class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "Bạn chưa đăng nhập",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // NÚT ĐĂNG NHẬP Ở ĐÂY
          ElevatedButton.icon(
            onPressed: () {
              // Chuyển sang màn hình LoginScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text("Đăng nhập / Đăng ký"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            "(Dành cho Nông dân & Nhà vận chuyển)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================
// PHẦN 2: GIAO DIỆN TRANG CHỦ
// ============================
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Header tùy chỉnh
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(
            Icons.looks_3, // Icon số 3 có sẵn
            color: Colors.white,
            size: 30,
          ),
        ),
        title: const Text(
          "3TML FARM",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: () {},
          ),
          // NÚT QUÉT QR Ở GÓC PHẢI
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
            // 1. Phần Banner cong cong màu xanh
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
                // Banner Quảng cáo
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0), // Màu cam nhạt
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: ResizeImage(
                          AssetImage('assets/images/banner-2.jpg'),
                          width: 800,
                        ),
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
                            "Transparency\nfrom garden\nto table.",
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

            // 2. Categories (Danh mục ngang)
            _buildSectionTitle("Categories", () {}),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip("Langsat", Icons.eco),
                  _buildCategoryChip("Dracontomelon", Icons.circle),
                  _buildCategoryChip("Carambola", Icons.star),
                  _buildCategoryChip("Avocado", Icons.lens),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Recommend Farm (Danh sách dọc)
            _buildSectionTitle("Recommend farm", () {}),

            // Danh sách các nông trại
            ListView.builder(
              shrinkWrap: true, // Quan trọng để nằm trong SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                return _buildFarmCard(context);
              },
            ),

            const SizedBox(height: 80), // Khoảng trống dưới cùng
          ],
        ),
      ),
    );
  }

  // Widget tiêu đề section
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
          GestureDetector(
            onTap: onPress,
            child: const Text("View all", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Widget Category Chip (Nút tròn tròn)
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

  // Widget Farm Card (Thẻ Nông trại)
  Widget _buildFarmCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Điều hướng sang màn hình chi tiết Nông trại
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
            // Ảnh cover nông trại
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/farm_1.jpg',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 600,
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
                      const Text(
                        "3TML Farm Corp",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.favorite_border, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Ho Chi Minh city",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
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
