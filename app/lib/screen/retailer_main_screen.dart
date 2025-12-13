import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

import 'dart:io';
import 'dart:convert';

import '../configs/constants.dart';

const Color kRetailerColor = Colors.indigo;

class RetailerMainScreen extends StatefulWidget {
  const RetailerMainScreen({super.key});

  @override
  State<RetailerMainScreen> createState() => _RetailerMainScreenState();
}

class _RetailerMainScreenState extends State<RetailerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const RetailerDashboardTab(),
    const Center(child: Text('Thống kê - Đang phát triển')),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cửa hàng'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kRetailerColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ==========================================
// TAB QUẢN LÝ KHO
// ==========================================
class RetailerDashboardTab extends StatefulWidget {
  const RetailerDashboardTab({super.key});

  @override
  State<RetailerDashboardTab> createState() => _RetailerDashboardTabState();
}

class _RetailerDashboardTabState extends State<RetailerDashboardTab> {
  List<Map<String, dynamic>> myInventory = [];
  bool _isLoading = false;
  String _storeName = "Đang tải...";
  String _storeAddress = "Đang cập nhật...";

  @override
  void initState() {
    super.initState();
    _fetchInventoryFromAPI();
    _loadStoreInfo();
  }

  // Hàm lấy thông tin từ bộ nhớ máy
  Future<void> _loadStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lấy tên cửa hàng (companyName), nếu chưa có thì lấy tên người dùng
      _storeName =
          prefs.getString('companyName') ??
          prefs.getString('fullName') ??
          "Cửa hàng của tôi";
      _storeAddress = prefs.getString('address') ?? "Chưa cập nhật vị trí";
    });
  }

  // --- API: LOAD DANH SÁCH ---
  Future<void> _fetchInventoryFromAPI() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/retailer-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          myInventory = List<Map<String, dynamic>>.from(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- HÀM UPLOAD ẢNH (MỚI THÊM) ---
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

  // --- API: QUÉT NHẬP KHO ---
  Future<void> _scanToImport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(isReturnData: true),
      ),
    );
    if (result != null && result.toString().isNotEmpty) {
      _fetchProductInfoToAdd(result.toString());
    }
  }

  Future<void> _fetchProductInfoToAdd(String productId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/$productId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        if (myInventory.any((e) => e['id'] == productId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sản phẩm này đã có trong kho!"),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        int deliveryDate = data['dates']['delivery'] ?? 0;
        int price = data['retailer']['price'] ?? 0;
        int status = 2;
        String statusText = "Chờ lên kệ";
        if (price > 0) {
          status = 3;
          statusText = "Đang bày bán";
        }

        setState(() {
          myInventory.insert(0, {
            "id": data['id'],
            "name": data['name'],
            "farm": data['farm']['name'],
            "image": data['images']['planting'] ?? "",
            "price": price > 0 ? "$price" : "",
            "statusCode": status,
            "status": statusText,
            "time": deliveryDate,
          });
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã nhập kho thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không tìm thấy sản phẩm"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- API: LÊN KỆ (CẬP NHẬT GIÁ & ẢNH) ---
  Future<void> _updateShelf(
    Map<String, dynamic> item,
    String price,
    String imageUrl,
  ) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateManagerInfo",
          "productId": item['id'],
          "managerReceiveDate": (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          "managerReceiveImageUrl": imageUrl, // GỬI ẢNH THẬT LÊN
          "price": int.parse(price),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lên kệ thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchInventoryFromAPI(); // Reload lại list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- API: BÁN HÀNG ---
  Future<void> _soldProduct(Map<String, dynamic> item) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "deactivateProduct",
          "productId": item['id'],
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          item['statusCode'] = 4;
          item['status'] = "Đã bán hết";
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã bán xong!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchInventoryFromAPI();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- UI: DIALOG CẬP NHẬT (CÓ CHỤP ẢNH) ---
  void _showUpdateShelfInfo(BuildContext context, Map<String, dynamic> item) {
    final priceController = TextEditingController();
    File? shelfImage;
    bool isUploading = false; // Loading cục bộ trong dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Lên Kệ & Định Giá"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Nhập giá bán và chụp ảnh trưng bày tại quầy.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  // 1. Nhập giá
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Giá bán (VNĐ)",
                      suffixText: "đ",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 2. Chụp ảnh
                  InkWell(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? img = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (img != null) {
                        setDialogState(() => shelfImage = File(img.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: shelfImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(shelfImage!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey),
                                Text("Chụp ảnh quầy"),
                              ],
                            ),
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
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Chưa nhập giá!")),
                            );
                            return;
                          }

                          // Upload ảnh nếu có (Không bắt buộc nhưng nên có)
                          String imageUrl = "";
                          setDialogState(() => isUploading = true);

                          if (shelfImage != null) {
                            String? url = await _uploadImage(shelfImage!);
                            if (url != null) imageUrl = url;
                          }

                          Navigator.pop(context); // Đóng dialog
                          _updateShelf(
                            item,
                            priceController.text,
                            imageUrl,
                          ); // Gọi hàm update
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRetailerColor,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          "Xác nhận",
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

  // ... (Hàm _showSellDialog và UI chính giữ nguyên) ...
  void _showSellDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận bán hàng"),
        content: Text("Xác nhận lô hàng ${item['name']} đã được bán hết?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _soldProduct(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Đã Bán", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRetailerColor,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _storeName,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _storeAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanToImport,
        backgroundColor: kRetailerColor,
        icon: const Icon(Icons.qr_code_2, color: Colors.white),
        label: const Text(
          "Quét Nhập Kho",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : myInventory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Kho trống\nHãy quét mã QR để nhập hàng mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: myInventory.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(myInventory[index]),
            ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "Vừa tới";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}";
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    int status = item['statusCode'];
    Color statusColor = status == 2
        ? Colors.orange
        : (status == 3 ? Colors.green : Colors.grey);
    int time = item['time'] ?? 0;
    String arrivalTime = _formatDate(time);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              title: Text(
                item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ID: ${item['id']}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Đã đến: $arrivalTime",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item['price'] != "") ...[
                        const SizedBox(width: 10),
                        Text(
                          "${item['price']} đ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (status == 2) ...[
              // Mới nhập -> Cần lên kệ
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateShelfInfo(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRetailerColor,
                  ),
                  icon: const Icon(
                    Icons.price_change,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "Cập nhật Giá & Lên Kệ",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ] else if (status == 3) ...[
              // Đang bán -> Bán xong
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSellDialog(context, item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text("Xác nhận Đã Bán Hết"),
                ),
              ),
            ] else if (status == 4) ...[
              const Divider(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      "Đã bán hết / Ngưng kinh doanh",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
