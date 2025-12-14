import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:convert';
import 'dart:io';

import '../configs/constants.dart';

import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

// Màu chủ đạo: Xanh dương đậm (Logistics) + Gradient
const Color kTransporterDark = Color(0xFF0D47A1);
const Color kTransporterLight = Color(0xFF1976D2);
const Color kBgColor = Color(0xFFF5F7FA);

class TransporterMainScreen extends StatefulWidget {
  const TransporterMainScreen({super.key});

  @override
  State<TransporterMainScreen> createState() => _TransporterMainScreenState();
}

class _TransporterMainScreenState extends State<TransporterMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const TransporterDashboardTab(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
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
        selectedItemColor: kTransporterDark,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

// ==========================================
// DASHBOARD TAB (GIAO DIỆN MỚI)
// ==========================================
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

  // --- 1. LOGIC API (GIỮ NGUYÊN) ---
  Future<void> _loadShipments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/my-shipments'),
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
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/upload/image'),
      );
      final mimeType = lookupMimeType(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _scanToReceive() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(isReturnData: true),
      ),
    );
    if (result != null && result.toString().isNotEmpty) {
      _showEvidenceDialog(context, result.toString(), isReceiving: true);
    }
  }

  // Gọi API Nhận hàng
  Future<void> _callReceiveAPI(String productId, [String? imageUrl]) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final companyName = prefs.getString('companyName');
    final fullName = prefs.getString('name');
    final submitName = (companyName != null && companyName.isNotEmpty)
        ? companyName
        : (fullName ?? "Tài xế");

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateReceive",
          "productId": productId,
          "transporterName": submitName,
          "receiveDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "receiveImageUrl": imageUrl ?? "",
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Gọi API Giao hàng
  Future<void> _confirmDelivery(String productId, [String? imageUrl]) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final companyName = prefs.getString('companyName');
    final fullName = prefs.getString('name');
    final submitName = (companyName != null && companyName.isNotEmpty)
        ? companyName
        : (fullName ?? "Tài xế");

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateDelivery",
          "productId": productId,
          "transporterName": submitName,
          "deliveryDate": (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          "deliveryImageUrl": imageUrl ?? "",
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

  // --- 2. DIALOG CHỤP ẢNH (ĐÃ FIX CAMERA SAU) ---
  void _showEvidenceDialog(
    BuildContext context,
    String productId, {
    required bool isReceiving,
  }) {
    File? evidenceImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc chọn
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                isReceiving ? "Xác nhận Nhận Hàng" : "Xác nhận Giao Hàng",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Vui lòng chụp ảnh ${isReceiving ? 'kiện hàng lúc nhận' : 'hàng tại điểm giao'} để làm bằng chứng.",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  // Khung ảnh
                  InkWell(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      // 🔥 FIX: Ép dùng Camera Sau (Rear)
                      final XFile? img = await picker.pickImage(
                        source: ImageSource.camera,
                        preferredCameraDevice: CameraDevice.rear,
                      );
                      if (img != null) {
                        setDialogState(() => evidenceImage = File(img.path));
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: evidenceImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(
                                evidenceImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: kTransporterDark.withOpacity(0.5),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Chạm để mở Camera sau",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (evidenceImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Chưa có ảnh bằng chứng!"),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isUploading = true);
                          String? imageUrl = await _uploadImage(evidenceImage!);
                          if (imageUrl != null) {
                            Navigator.pop(context);
                            if (isReceiving)
                              _callReceiveAPI(productId, imageUrl);
                            else
                              _confirmDelivery(productId, imageUrl);
                          } else {
                            setDialogState(() => isUploading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTransporterDark,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          "Gửi Báo Cáo",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. GIAO DIỆN CHÍNH ĐƯỢC LÀM MỚI ---
  @override
  Widget build(BuildContext context) {
    // Thống kê nhanh
    int inTransit = myShipments.where((e) => e['statusCode'] == 1).length;
    int completed = myShipments.where((e) => e['statusCode'] == 2).length;

    return Scaffold(
      backgroundColor: kBgColor,

      // FAB Nút Quét To Đẹp
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanToReceive,
        backgroundColor: kTransporterDark,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          "NHẬN ĐƠN",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // HEADER CONG (Gradient)
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kTransporterDark, kTransporterLight],
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
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xin chào, Tài xế",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Dashboard Vận Chuyển",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.local_shipping, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Thống kê
                Row(
                  children: [
                    _buildHeaderStat(
                      "Đang chở",
                      "$inTransit",
                      Icons.local_shipping,
                      Colors.orangeAccent,
                    ),
                    const SizedBox(width: 15),
                    _buildHeaderStat(
                      "Đã giao",
                      "$completed",
                      Icons.check_circle,
                      Colors.lightGreenAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // DANH SÁCH ĐƠN HÀNG
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : myShipments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const Text(
                          "Chưa có chuyến hàng nào.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
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
          ),
        ],
      ),
    );
  }

  // Widget Thống kê Header
  Widget _buildHeaderStat(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Card Đơn hàng (Đã nâng cấp)
  Widget _buildTransportCard(Map<String, dynamic> item) {
    int status = item['statusCode'] ?? 1;
    bool isInTransit = (status == 1);
    String farmName = item['farmName'] ?? "Nông trại";
    String locationDisplay = isInTransit
        ? "Từ: $farmName ➡️ Kho Tổng"
        : "Giao thành công";

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(
              color: isInTransit ? Colors.orange : Colors.green,
              width: 5,
            ),
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['image'] ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isInTransit
                                  ? Colors.orange[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isInTransit ? "Đang chở" : "Hoàn tất",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isInTransit
                                    ? Colors.orange[800]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Mã lô: ${item['id']}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: isInTransit
                            ? () => _openMap("Ho Chi Minh City")
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isInTransit ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isInTransit
                                      ? Colors.blue[800]
                                      : Colors.black87,
                                  fontWeight: isInTransit
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  decoration: isInTransit
                                      ? TextDecoration.underline
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
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

            // NÚT HÀNH ĐỘNG (Đã làm đẹp hơn)
            if (isInTransit) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tính năng đang phát triển"),
                            ),
                          ),
                      icon: const Icon(Icons.thermostat, size: 18),
                      label: const Text("Cập nhật"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[800],
                        side: BorderSide(color: Colors.blue.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEvidenceDialog(
                        context,
                        item['id'],
                        isReceiving: false,
                      ),
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text("Đã Giao"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTransporterDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
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
