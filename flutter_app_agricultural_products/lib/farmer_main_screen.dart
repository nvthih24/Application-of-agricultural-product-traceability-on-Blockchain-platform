import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart'; // Import màn hình đăng nhập để logout
import '../farmer_dashboard_screen.dart'; // Import màn hình Form nhập liệu cũ của bạn

// Màu xanh đậm hơn một chút cho giao diện quản lý
const Color kFarmerPrimaryColor = Color(0xFF2E7D32);

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});

  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  // Dữ liệu giả lập (Sau này thay bằng API: contract.getProductsByFarmer)
  final List<Map<String, dynamic>> myCrops = [
    {
      "id": "CAITHIA-001",
      "name": "Cải thìa hữu cơ",
      "date": "15/11/2025",
      "status": "Đang gieo trồng",
      "image": "assets/images/farm_1.jpg",
      "canHarvest": true, // Có thể thu hoạch
    },
    {
      "id": "DUAHAU-088",
      "name": "Dưa hấu Long An",
      "date": "01/10/2025",
      "status": "Đã thu hoạch",
      "image": "assets/images/fruit.png",
      "canHarvest": false, // Đã xong
    },
  ];

  // Hàm Đăng xuất
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa token và role
    if (mounted) {
      // Quay về màn hình Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // 1. AppBar: Tên Nông Trại & Logout
      appBar: AppBar(
        backgroundColor: kFarmerPrimaryColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Nông Dân",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Pione Farm",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),

      // 2. Nút Thêm Mới (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Chuyển sang màn hình Form nhập liệu (FarmerDashboardScreen cũ)
          // Để nông dân thêm sản phẩm mới
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmerDashboardScreen(),
            ),
          );
        },
        backgroundColor: kFarmerPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm Mùa Vụ", style: TextStyle(color: Colors.white)),
      ),

      // 3. Nội dung chính
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Thống kê nhanh
            Row(
              children: [
                _buildStatCard(
                  "Tổng sản phẩm",
                  "${myCrops.length}",
                  Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildStatCard("Đang trồng", "1", Colors.orange),
                const SizedBox(width: 15),
                _buildStatCard("Đã xong", "1", Colors.green),
              ],
            ),

            const SizedBox(height: 25),
            const Text(
              "Danh sách sản phẩm",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Danh sách sản phẩm (ListView)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myCrops.length,
              itemBuilder: (context, index) {
                return _buildCropCard(myCrops[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Thẻ thống kê nhỏ
  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ), // Viền màu bên trái
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Thẻ sản phẩm chi tiết
  Widget _buildCropCard(Map<String, dynamic> crop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    crop['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    // Nếu ảnh lỗi thì hiện icon
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Thông tin chữ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "ID: ${crop['id']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: crop['canHarvest']
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: crop['canHarvest']
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        child: Text(
                          crop['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: crop['canHarvest']
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            // Hàng nút hành động
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (crop['canHarvest'])
                  TextButton.icon(
                    onPressed: () {
                      // Mở form cập nhật thu hoạch (Truyền ID sang)
                      // Navigator.push(...)
                    },
                    icon: const Icon(
                      Icons.agriculture,
                      size: 18,
                      color: Colors.orange,
                    ),
                    label: const Text(
                      "Thu hoạch",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () {
                    // Xem QR Code
                  },
                  icon: const Icon(Icons.qr_code, size: 18, color: Colors.blue),
                  label: const Text(
                    "Mã QR",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
