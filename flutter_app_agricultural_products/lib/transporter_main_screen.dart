import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart'; // Dùng lại màn hình quét mã

// Màu chủ đạo: Xanh dương (Logistics)
const Color kTransporterColor = Color(0xFF01579B);
const Color kAccentColor = Color(0xFF0288D1);

class TransporterMainScreen extends StatefulWidget {
  const TransporterMainScreen({super.key});

  @override
  State<TransporterMainScreen> createState() => _TransporterMainScreenState();
}

class _TransporterMainScreenState extends State<TransporterMainScreen> {
  // Dữ liệu giả lập lịch sử vận chuyển
  final List<Map<String, dynamic>> history = [
    {
      "id": "CAITHIA-001",
      "action": "Nhận hàng (Pickup)",
      "time": "10:30 AM",
      "location": "Pione Farm, Khu A",
      "status": "success",
    },
    {
      "id": "DUAHAU-088",
      "action": "Giao hàng (Delivery)",
      "time": "08:15 AM",
      "location": "Kho lạnh số 2",
      "status": "success",
    },
    {
      "id": "CAM-002",
      "action": "Nhận hàng",
      "time": "Yesterday",
      "location": "Nông trại Cam Bè",
      "status": "pending",
    },
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _startScan() {
    // Mở màn hình quét QR
    // Lưu ý: Sau này chúng ta sẽ sửa logic chỗ này một chút
    // để khi Transporter quét xong thì hiện Form "Cập nhật vận chuyển"
    // thay vì hiện Chi tiết sản phẩm như người tiêu dùng.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // 1. Header
      appBar: AppBar(
        backgroundColor: kTransporterColor,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Vận Chuyển",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Tài xế: Nguyễn Văn A",
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      body: Column(
        children: [
          // 2. Khu vực Hành động chính (Quét QR)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: kTransporterColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Nút quét to đùng
                GestureDetector(
                  onTap: _startScan,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: kTransporterColor,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "QUÉT ĐƠN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kTransporterColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Di chuyển camera đến mã QR trên kiện hàng",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // 3. Thống kê nhanh
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                _buildStatCard(
                  "Đã nhận",
                  "15",
                  Icons.inventory_2,
                  Colors.orange,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Đã giao",
                  "42",
                  Icons.local_shipping,
                  Colors.green,
                ),
              ],
            ),
          ),

          // 4. Lịch sử hoạt động
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hoạt động gần đây",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Danh sách cuộn
                  Expanded(
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item['action'].contains("Nhận")
                                      ? Icons.input
                                      : Icons.output,
                                  color: kTransporterColor,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['id'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      item['action'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['location'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item['time'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (item['status'] == 'success')
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    )
                                  else
                                    const Icon(
                                      Icons.access_time_filled,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
