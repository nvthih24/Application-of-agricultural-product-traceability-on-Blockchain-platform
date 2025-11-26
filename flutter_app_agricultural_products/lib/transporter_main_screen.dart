import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart'; // Nhớ import Profile

const Color kTransporterColor = Color(0xFF01579B);

// ==========================================
// 1. MÀN HÌNH CHÍNH (CHỨA MENU DƯỚI ĐÁY)
// ==========================================
class TransporterMainScreen extends StatefulWidget {
  const TransporterMainScreen({super.key});

  @override
  State<TransporterMainScreen> createState() => _TransporterMainScreenState();
}

class _TransporterMainScreenState extends State<TransporterMainScreen> {
  int _selectedIndex = 0;

  // Danh sách các Tab
  static final List<Widget> _pages = [
    const TransporterDashboardTab(), // Tab 0: Dashboard chính
    const Center(child: Text("Thông báo (Đang phát triển)")), // Tab 1
    const ProfileScreen(), // Tab 2: Tài khoản
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Vận chuyển',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kTransporterColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ================
// 2. TAB DASHBOARD
// ================
class TransporterDashboardTab extends StatefulWidget {
  const TransporterDashboardTab({super.key});

  @override
  State<TransporterDashboardTab> createState() =>
      _TransporterDashboardTabState();
}

class _TransporterDashboardTabState extends State<TransporterDashboardTab> {
  List<dynamic> myShipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  // Gọi API lấy danh sách
  Future<void> _loadShipments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/my-shipments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          myShipments = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  // Xử lý quét mã nhận hàng
  Future<void> _scanToReceive() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(isReturnData: true),
      ),
    );

    if (result != null && result.toString().isNotEmpty) {
      _callReceiveAPI(result.toString());
    }
  }

  // Gọi API Update Receive
  Future<void> _callReceiveAPI(String productId) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Logic lấy tên chuẩn để khớp với Backend
    final companyName = prefs.getString('companyName');
    final fullName = prefs.getString('name');
    final submitName = (companyName != null && companyName.isNotEmpty)
        ? companyName
        : (fullName ?? "Tài xế");

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateReceive",
          "productId": productId,
          "transporterName": submitName, // Gửi tên chuẩn
          "receiveDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "receiveImageUrl": "",
          "transportInfo": "Xe lạnh (Tài xế: ${fullName ?? 'N/A'})",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã nhận hàng thành công!"),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _loadShipments();
        });
      } else {
        String errorMsg = response.body;
        if (errorMsg.contains("already updated")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đơn này đã được nhận rồi!"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi: $errorMsg"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Gọi API Giao hàng
  Future<void> _confirmDelivery(String productId) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Logic lấy tên chuẩn (giống hàm Receive)
    final companyName = prefs.getString('companyName');
    final fullName = prefs.getString('name');
    final submitName = (companyName != null && companyName.isNotEmpty)
        ? companyName
        : (fullName ?? "Tài xế");

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateDelivery",
          "productId": productId,
          "transporterName":
              submitName, // Phải trùng tên lúc nhận thì contract mới cho giao
          "deliveryDate": (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          "deliveryImageUrl": "",
          "transportInfo": "Giao thành công tại kho",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giao hàng thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _loadShipments();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap(String address) async {
    final Uri googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Không mở được bản đồ")));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kTransporterColor,
        title: const Text(
          "Dashboard Vận Chuyển",
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false, // Tắt nút back thừa
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanToReceive,
        backgroundColor: kTransporterColor,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          "Nhận Đơn Mới",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : myShipments.isEmpty
          ? const Center(
              child: Text(
                "Chưa có đơn hàng nào.\nHãy quét mã từ Nông dân để nhận.",
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadShipments,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: myShipments.length,
                itemBuilder: (context, index) =>
                    _buildTransportCard(myShipments[index]),
              ),
            ),
    );
  }

  Widget _buildTransportCard(Map<String, dynamic> item) {
    int status = item['statusCode'] ?? 1;
    bool isInTransit = (status == 1);
    String farmName = item['farmName'] ?? "Nông trại";

    String locationDisplay = isInTransit
        ? "Từ: $farmName ➡️ Kho Tổng" // Dữ liệu thật kết hợp logic
        : "Đã giao tại Siêu Thị";
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
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
                      child: const Icon(Icons.local_shipping),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
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
                      Text(
                        "ID: ${item['id']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: isInTransit
                            ? () => _openMap("Kho trung chuyển")
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isInTransit ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locationDisplay,
                              style: TextStyle(
                                color: isInTransit ? Colors.blue : Colors.black,
                                decoration: isInTransit
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // NÚT HÀNH ĐỘNG (CHỈ HIỆN KHI ĐANG ĐI)
            if (isInTransit) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                children: [
                  // NÚT 1: CẬP NHẬT NHIỆT ĐỘ / TRẠNG THÁI
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Gọi hàm show dialog cập nhật (nếu chưa có thì tạo hàm giả hoặc bỏ qua)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tính năng đang phát triển"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTransporterColor,
                        side: const BorderSide(color: kTransporterColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.thermostat, size: 18),
                      label: const Text("Cập nhật"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // NÚT 2: XÁC NHẬN GIAO
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelivery(item['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTransporterColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Đã Giao",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
