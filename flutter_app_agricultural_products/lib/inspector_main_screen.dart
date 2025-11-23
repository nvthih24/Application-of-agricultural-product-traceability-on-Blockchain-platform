import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

const Color kInspectorColor = Color(0xFF6A1B9A); // Tím đậm
const Color kInspectorLight = Color(0xFF9C4DCC); // Tím nhạt

class InspectorMainScreen extends StatefulWidget {
  const InspectorMainScreen({super.key});

  @override
  State<InspectorMainScreen> createState() => _InspectorMainScreenState();
}

class _InspectorMainScreenState extends State<InspectorMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // DỮ LIỆU GIẢ LẬP
  List<Map<String, dynamic>> pendingPlanting = [
    {
      "id": "CAITHIA-NEW-001",
      "name": "Cải thìa hữu cơ",
      "farm": "3TML Farm",
      "date": "23/11/2025",
      "image": "assets/images/farm_1.jpg",
      "type": "planting",
    },
    {
      "id": "RAU-NEW-002",
      "name": "Rau muống",
      "farm": "Green Farm",
      "date": "23/11/2025",
      "image": "assets/images/farm_1.jpg",
      "type": "planting",
    },
  ];

  List<Map<String, dynamic>> pendingHarvest = [
    {
      "id": "DUAHAU-HARVEST-88",
      "name": "Dưa hấu Long An",
      "farm": "3TML Farm",
      "date": "20/02/2026",
      "quantity": "500 kg",
      "image": "assets/images/fruit.png",
      "type": "harvest",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Hàm hiển thị hộp thoại xác nhận đăng xuất
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Đăng xuất"),
          content: const Text(
            "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?",
          ),
          actions: [
            // Nút 1: Quay lại (Hủy)
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại, không làm gì cả
              },
              child: const Text(
                "Quay lại",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            // Nút 2: Đăng xuất (Thực hiện)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Màu đỏ cảnh báo
              ),
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại trước
                _logout(); // Gọi hàm đăng xuất thật
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
    await prefs.clear(); // Xóa token đăng nhập

    if (mounted) {
      // Xóa sạch lịch sử, quay về trang Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _processRequest(Map<String, dynamic> item, bool isApproved) {
    setState(() {
      if (item['type'] == 'planting') {
        pendingPlanting.remove(item);
      } else {
        pendingHarvest.remove(item);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isApproved ? "Đã DUYỆT thành công!" : "Đã TỪ CHỐI yêu cầu!",
        ),
        backgroundColor: isApproved ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tính tổng việc cần làm
    int totalTasks = pendingPlanting.length + pendingHarvest.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. CUSTOM HEADER (THAY CHO APPBAR CŨ)
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kInspectorColor, kInspectorLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng trên cùng: Chào mừng & Logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào, Moderator",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Cần xử lý: $totalTasks yêu cầu",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _showLogoutDialog,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 2. CUSTOM TAB BAR (NẰM TRONG HEADER)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelColor: kInspectorColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      _buildTabWithBadge("Gieo Trồng", pendingPlanting.length),
                      _buildTabWithBadge("Thu Hoạch", pendingHarvest.length),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. NỘI DUNG DANH SÁCH
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(
                  pendingPlanting,
                  "Sạch sẽ! Không có yêu cầu gieo trồng mới.",
                ),
                _buildList(
                  pendingHarvest,
                  "Tuyệt vời! Đã duyệt hết yêu cầu thu hoạch.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Tab có số lượng (Badge)
  Widget _buildTabWithBadge(String title, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(items[index]);
      },
    );
  }

  // ... (Hàm _buildRequestCard giữ nguyên như cũ của ông, chỉ đổi style nút cho đẹp tí nếu muốn)
  Widget _buildRequestCard(Map<String, dynamic> item) {
    bool isHarvest = item['type'] == 'harvest';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3, // Tăng độ nổi
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0), // Tăng padding
        child: Column(
          children: [
            // Phần thông tin (Giữ nguyên logic cũ)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item['image'],
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge loại yêu cầu
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHarvest
                              ? Colors.orange[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isHarvest
                              ? "Yêu cầu Thu Hoạch"
                              : "Yêu cầu Gieo Trồng",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isHarvest
                                ? Colors.orange[800]
                                : Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Farm: ${item['farm']}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isHarvest
                            ? "Sản lượng: ${item['quantity']}"
                            : "Ngày gửi: ${item['date']}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Phần Nút Bấm (Làm to rõ hơn)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processRequest(item, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Từ chối"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processRequest(item, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Chấp thuận"),
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
