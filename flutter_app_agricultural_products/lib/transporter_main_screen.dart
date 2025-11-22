import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Nhớ cài: flutter pub add url_launcher
import 'qr_scanner_screen.dart';
import 'home_screen.dart';

const Color kTransporterColor = Color(0xFF01579B);

class TransporterMainScreen extends StatefulWidget {
  const TransporterMainScreen({super.key});

  @override
  State<TransporterMainScreen> createState() => _TransporterMainScreenState();
}

class _TransporterMainScreenState extends State<TransporterMainScreen> {
  // Dữ liệu giả lập
  final List<Map<String, dynamic>> myShipments = [
    {
      "id": "CAITHIA-BATCH-001",
      "name": "Cải thìa hữu cơ",
      "location": "Kho A, KCN Tân Bình", // Địa chỉ để tìm trên Map
      "time": "10:30 AM",
      "statusCode": 1, // 1: Đang vận chuyển
      "status": "In Transit",
      "image": "assets/images/farm_1.jpg",
    },
    {
      "id": "DUAHAU-BATCH-088",
      "name": "Dưa hấu Long An",
      "location": "Siêu thị BigC",
      "time": "08:15 AM",
      "statusCode": 2, // 2: Đã giao
      "status": "Completed",
      "image": "assets/images/fruit.png",
    },
  ];

  // --- HÀM MỞ MAP (ĐÃ SỬA URL CHUẨN) ---
  Future<void> _openMap(String address) async {
    // Tạo URL tìm kiếm địa điểm trên Google Maps
    final Uri googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không tìm thấy ứng dụng bản đồ!")),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- CÁC HÀM DIALOG VÀ LOGOUT GIỮ NGUYÊN ---
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

  void _showUpdateConditionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật hành trình"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              decoration: InputDecoration(
                labelText: "Nhiệt độ (°C)",
                prefixIcon: Icon(Icons.ac_unit),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: "Vị trí hiện tại",
                prefixIcon: Icon(Icons.location_on),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Đã cập nhật!")));
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeliveryDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận giao hàng"),
        content: Text("Xác nhận đã giao đơn ${item['name']} thành công?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = myShipments.indexWhere(
                  (e) => e['id'] == item['id'],
                );
                if (index != -1) {
                  myShipments[index]['statusCode'] = 2;
                  myShipments[index]['status'] = "Completed";
                  myShipments[index]['location'] = "Giao thành công";
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Giao hàng thành công!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kTransporterColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard Vận Chuyển", style: TextStyle(fontSize: 18)),
            Text(
              "Tài xế: Nguyễn Văn A",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed:
                _showLogoutDialog, // Gọi hộp thoại thay vì gọi logout ngay
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const QrScannerScreen()),
        ),
        backgroundColor: kTransporterColor,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          "Quét Nhận Hàng",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: myShipments.length,
        itemBuilder: (context, index) =>
            _buildTransportCard(myShipments[index]),
      ),
    );
  }

  // --- WIDGET CARD ĐÃ TỐI ƯU GIAO DIỆN ---
  Widget _buildTransportCard(Map<String, dynamic> item) {
    int status = item['statusCode'] ?? 1;
    bool isInTransit = (status == 1);
    String location = item['location'];

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 1. Phần thông tin
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item['image'] ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.local_shipping),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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

                      // --- LOGIC NÚT MAP: NẰM GỌN Ở ĐÂY ---
                      InkWell(
                        onTap: isInTransit
                            ? () => _openMap(location)
                            : null, // Chỉ bấm được khi đang đi
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isInTransit ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isInTransit
                                      ? Colors.blue[800]
                                      : Colors.black87,
                                  fontWeight: isInTransit
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  decoration: isInTransit
                                      ? TextDecoration.underline
                                      : TextDecoration
                                            .none, // Gạch chân để biết là bấm được
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isInTransit)
                              const Icon(
                                Icons.open_in_new,
                                size: 12,
                                color: Colors.blue,
                              ), // Icon mũi tên nhỏ
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. Phần nút bấm (Chỉ hiện khi đang vận chuyển)
            if (isInTransit) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUpdateConditionDialog(context),
                      icon: const Icon(Icons.thermostat, size: 18),
                      label: const Text("Cập nhật"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTransporterColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showConfirmDeliveryDialog(context, item),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Hoàn tất"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTransporterColor,
                        foregroundColor: Colors.white,
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
