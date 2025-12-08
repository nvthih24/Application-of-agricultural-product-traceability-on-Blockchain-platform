import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../configs/constants.dart';

const Color kInspectorColor = Color(0xFF6A1B9A);
const Color kInspectorLight = Color(0xFF9C4DCC);

// ==========================================
// 1. MÀN HÌNH CHÍNH (MENU DƯỚI)
// ==========================================
class InspectorMainScreen extends StatefulWidget {
  const InspectorMainScreen({super.key});

  @override
  State<InspectorMainScreen> createState() => _InspectorMainScreenState();
}

class _InspectorMainScreenState extends State<InspectorMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const InspectorDashboardTab(), // Tab 0: Chờ duyệt (Code cũ)
    const InspectorHistoryTab(), // Tab 1: Lịch sử (Mới)
    const NotificationScreen(), // Tab 2: Thông báo
    const ProfileScreen(), // Tab 3: Tài khoản
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Chờ duyệt',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kInspectorColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ==========================================
// 2. TAB DASHBOARD (CHỜ DUYỆT)
// ==========================================
class InspectorDashboardTab extends StatefulWidget {
  const InspectorDashboardTab({super.key});

  @override
  State<InspectorDashboardTab> createState() => _InspectorDashboardTabState();
}

class _InspectorDashboardTabState extends State<InspectorDashboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> pendingPlanting = [];
  List<dynamic> pendingHarvest = [];

  String? _processingItemId;

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
        Uri.parse('${Constants.baseUrl}/products/pending-requests'),
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
      setState(() => _isLoading = false);
    }
  }

  // 2. HÀM DUYỆT / TỪ CHỐI (GỌI TRANSACTION API)
  Future<void> _processRequest(
    Map<String, dynamic> item,
    bool isApproved,
  ) async {
    setState(() => _isLoading = true);
    _processingItemId = item['id'];

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
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'productId': item['id']}),
      );

      if (response.statusCode == 200) {
        _removeItemFromList(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? "Đã DUYỆT thành công!" : "Đã TỪ CHỐI!"),
            backgroundColor: isApproved ? Colors.green : Colors.orange,
          ),
        );
      } else {
        // XỬ LÝ LỖI THÔNG MINH
        final errorBody = jsonDecode(response.body);
        final String errorDetails = errorBody['details'] ?? "";

        // Nếu lỗi là "đã làm rồi" (not pending) -> Coi như xong, xóa luôn
        if (errorDetails.contains("not pending")) {
          _removeItemFromList(item);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Yêu cầu này đã được xử lý trước đó!"),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          throw Exception(errorBody['error']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _processingItemId = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );

      // GIẢ LẬP THÀNH CÔNG ĐỂ TEST UI:
      // setState(() {
      //   if (item['type'] == 'planting')
      //     pendingPlanting.remove(item);
      //   else
      //     pendingHarvest.remove(item);
      // });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  // Hàm phụ để xóa item khỏi list
  void _removeItemFromList(Map<String, dynamic> item) {
    setState(() {
      if (item['type'] == 'planting') {
        pendingPlanting.removeWhere((e) => e['id'] == item['id']);
      } else {
        pendingHarvest.removeWhere((e) => e['id'] == item['id']);
      }
    });
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
                const Text(
                  "Danh sách chờ duyệt",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
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
                        item['name'] ?? "Sản phẩm",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            // Thêm Expanded để tên dài không bị lỗi
                            child: Text(
                              "Farm: ${item['farm'] ?? 'Chưa cập nhật'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                // NÚT DUYỆT
                Expanded(
                  child: ElevatedButton(
                    // Nếu đang loading VÀ đúng là item này -> Disable nút
                    onPressed: (_isLoading && _processingItemId == item['id'])
                        ? null
                        : () => _processRequest(item, true),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    // Hiển thị vòng quay nếu đang xử lý đúng item này
                    child: (_isLoading && _processingItemId == item['id'])
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Chấp thuận"),
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

// ==========================================
// 3. TAB LỊCH SỬ
// ==========================================
class InspectorHistoryTab extends StatefulWidget {
  const InspectorHistoryTab({super.key});

  @override
  State<InspectorHistoryTab> createState() => _InspectorHistoryTabState();
}

class _InspectorHistoryTabState extends State<InspectorHistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> historyPlanting = [];
  List<dynamic> historyHarvest = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/moderated-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          historyPlanting = data['planting'];
          historyHarvest = data['harvest'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhẹ
      appBar: AppBar(
        backgroundColor: kInspectorColor, // Dùng màu tím chủ đạo
        title: const Text(
          "Lịch sử kiểm duyệt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.grass), text: "Gieo Trồng"),
            Tab(icon: Icon(Icons.inventory), text: "Thu Hoạch"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kInspectorColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(
                  historyPlanting,
                  "Chưa có lịch sử gieo trồng.",
                ),
                _buildHistoryList(historyHarvest, "Chưa có lịch sử thu hoạch."),
              ],
            ),
    );
  }

  Widget _buildHistoryList(List<dynamic> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildHistoryCard(items[i]),
    );
  }

  // Widget Card Đẹp (Đồng bộ với Dashboard)
  Widget _buildHistoryCard(dynamic item) {
    bool isApproved = item['statusCode'] == 1; // 1: Approved, 2: Rejected
    Color statusColor = isApproved ? Colors.green : Colors.red;
    String statusText = isApproved ? "Đã Chấp Thuận" : "Đã Từ Chối";
    IconData statusIcon = isApproved ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Ảnh sản phẩm
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Farm: ${item['farm']}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${item['id']}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Hàng trạng thái & Ngày tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ngày xử lý (Nếu có timestamp thì format, ko thì hiện N/A)
                Text(
                  _formatDate(item['date']), // Hàm format date dùng chung
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }
}
