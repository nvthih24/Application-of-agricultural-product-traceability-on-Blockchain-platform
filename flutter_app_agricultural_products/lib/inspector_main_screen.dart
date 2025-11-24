import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // flutter pub add intl
import 'home_screen.dart';

const Color kInspectorColor = Color(0xFF6A1B9A);
const Color kInspectorLight = Color(0xFF9C4DCC);

class InspectorMainScreen extends StatefulWidget {
  const InspectorMainScreen({super.key});

  @override
  State<InspectorMainScreen> createState() => _InspectorMainScreenState();
}

class _InspectorMainScreenState extends State<InspectorMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> pendingPlanting = [];
  List<dynamic> pendingHarvest = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPendingRequests();
  }

  // 1. GỌI API LẤY DANH SÁCH CHỜ
  Future<void> _fetchPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/pending-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          pendingPlanting = data['planting'];
          pendingHarvest = data['harvest'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi lấy danh sách: $e");
      setState(() => _isLoading = false);
    }
  }

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

  // 2. HÀM DUYỆT / TỪ CHỐI (GỌI TRANSACTION API)
  Future<void> _processRequest(
    Map<String, dynamic> item,
    bool isApproved,
  ) async {
    setState(() => _isLoading = true);

    String action = "";
    if (item['type'] == 'planting') {
      action = isApproved ? 'approvePlanting' : 'rejectPlanting';
    } else {
      action = isApproved ? 'approveHarvest' : 'rejectHarvest';
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'productId': item['id']}),
      );

      if (response.statusCode == 200) {
        // Xóa item khỏi list hiển thị
        setState(() {
          if (item['type'] == 'planting') {
            pendingPlanting.remove(item);
          } else {
            pendingHarvest.remove(item);
          }
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? "Đã DUYỆT thành công!" : "Đã TỪ CHỐI!"),
            backgroundColor: isApproved ? Colors.green : Colors.orange,
          ),
        );
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = pendingPlanting.length + pendingHarvest.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // HEADER
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
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào, Moderator",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Cần xử lý: $totalTasks yêu cầu",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
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
                    tabs: [
                      _buildTabWithBadge("Gieo Trồng", pendingPlanting.length),
                      _buildTabWithBadge("Thu Hoạch", pendingHarvest.length),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        pendingPlanting,
                        "Không có yêu cầu gieo trồng mới.",
                      ),
                      _buildList(
                        pendingHarvest,
                        "Không có yêu cầu thu hoạch mới.",
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

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
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String emptyMsg) {
    if (items.isEmpty)
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );

    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildRequestCard(items[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    bool isHarvest = item['type'] == 'harvest';
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['image'] ?? '',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Farm: ${item['farm']}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Ngày: ${_formatDate(item['date'])}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processRequest(item, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
