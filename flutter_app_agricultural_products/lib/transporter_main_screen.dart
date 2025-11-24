import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';

const Color kTransporterColor = Color(0xFF01579B);

class TransporterMainScreen extends StatefulWidget {
  const TransporterMainScreen({super.key});

  @override
  State<TransporterMainScreen> createState() => _TransporterMainScreenState();
}

class _TransporterMainScreenState extends State<TransporterMainScreen> {
  List<dynamic> myShipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  // 1. GỌI API LẤY DANH SÁCH ĐƠN HÀNG
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

  // 2. XỬ LÝ QUÉT MÃ NHẬN HÀNG (PICKUP)
  Future<void> _scanToReceive() async {
    // Mở Camera quét mã
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(isReturnData: true),
      ),
      // Lưu ý: Cần sửa QrScannerScreen chút xíu để nó trả về dữ liệu thay vì push trang mới
      // Nếu ông chưa sửa file QR, thì dùng tạm cách nhập tay bên dưới hoặc sửa file QR sau.
    );

    // Nếu quét được mã (Ví dụ result là 'BATCH-123...')
    if (result != null && result.toString().isNotEmpty) {
      _callReceiveAPI(result.toString());
    }
  }

  // Gọi API nhận hàng
  Future<void> _callReceiveAPI(String productId) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('name') ?? "Tài xế";

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
          "transporterName": name, // Gửi tên thật để lọc
          "receiveDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "receiveImageUrl": "", // Có thể thêm chụp ảnh xác nhận
          "transportInfo": "Xe lạnh 29C-12345",
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
          if (mounted) {
            _loadShipments(); // Gọi hàm này để refresh trang
          }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi kết nối"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. XỬ LÝ GIAO HÀNG (DELIVERY)
  Future<void> _confirmDelivery(String productId) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('name') ?? "Tài xế";

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
          "transporterName":
              name, // QUAN TRỌNG: Gửi tên mình lên để "đánh dấu chủ quyền"
          "receiveDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "receiveImageUrl": "",
          "transportInfo": "Xe lạnh 29C-12345",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã nhận hàng thành công!"),
            backgroundColor: Colors.green,
          ),
        );

        // CHỜ 3 GIÂY ĐỂ BLOCKCHAIN CẬP NHẬT
        // Sau đó gọi _loadShipments: Lúc này API sẽ thấy transporterName == user.fullName -> Trả về list
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

  // Hàm mở Google Maps
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      // NÚT QUÉT QR NHẬN HÀNG
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
    String location = item['location'] ?? "Không xác định";

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

                      // NÚT CHỈ ĐƯỜNG
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
                              location,
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
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelivery(item['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTransporterColor,
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    "Xác nhận đã giao",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
