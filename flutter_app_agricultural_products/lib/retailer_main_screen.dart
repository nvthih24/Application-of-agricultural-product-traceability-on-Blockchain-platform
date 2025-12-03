import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';

const Color kRetailerColor = Colors.indigo;

class RetailerMainScreen extends StatefulWidget {
  const RetailerMainScreen({super.key});

  @override
  State<RetailerMainScreen> createState() => _RetailerMainScreenState();
}

class _RetailerMainScreenState extends State<RetailerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const RetailerDashboardTab(), // Tab 0: Quản lý kho
    const Center(child: Text("Thống kê (Đang phát triển)")), // Tab 1
    const ProfileScreen(), // Tab 2
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
// TAB QUẢN LÝ KHO (DASHBOARD)
// ==========================================
class RetailerDashboardTab extends StatefulWidget {
  const RetailerDashboardTab({super.key});

  @override
  State<RetailerDashboardTab> createState() => _RetailerDashboardTabState();
}

class _RetailerDashboardTabState extends State<RetailerDashboardTab> {
  List<Map<String, dynamic>> myInventory = [];
  bool _isLoading = false; // Ban đầu không load vì chưa có API lấy list riêng

  @override
  void initState() {
    super.initState();
    _fetchInventoryFromAPI();
  }

  // 1. HÀM QUÉT MÃ NHẬP KHO
  Future<void> _scanToImport() async {
    // Mở màn hình quét QR
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

  // Lấy thông tin sản phẩm từ Blockchain để thêm vào list tạm
  Future<void> _fetchProductInfoToAdd(String productId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/$productId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        // Kiểm tra trùng
        if (myInventory.any((e) => e['id'] == productId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sản phẩm này đã có trong danh sách!"),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Kiểm tra trạng thái (Phải giao xong mới được nhập)
        int deliveryDate = data['dates']['delivery'] ?? 0;
        int price = data['retailer']['price'] ?? 0;

        int status = 2; // Mặc định: Mới nhận
        String statusText = "Chờ lên kệ";

        if (price > 0) {
          status = 3;
          statusText = "Đang bày bán";
        }
        // Nếu contract có trạng thái 'Sold' thì check thêm status=4

        setState(() {
          myInventory.insert(0, {
            // Thêm lên đầu
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
        _fetchInventoryFromAPI(); // Lưu lại sau khi thêm
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã thêm vào danh sách nhập kho!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không tìm thấy sản phẩm này"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  // 2. HÀM LÊN KỆ (GỌI API UPDATE)
  Future<void> _updateShelf(Map<String, dynamic> item, String price) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateManagerInfo",
          "productId": item['id'],
          "managerReceiveDate": (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          "managerReceiveImageUrl":
              "", // (Tạm thời để rỗng hoặc thêm chụp ảnh sau)
          "price": int.parse(price),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          item['statusCode'] = 3;
          item['status'] = "Đang bày bán";
          item['price'] = price;
          _isLoading = false;
        });
        _fetchInventoryFromAPI(); // Lưu lại sau khi cập nhật
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lên kệ thành công!"),
            backgroundColor: Colors.green,
          ),
        );
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
      print(e);
      setState(() => _isLoading = false);
    }
  }

  // 3. HÀM BÁN (SOLD)
  Future<void> _soldProduct(Map<String, dynamic> item) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "deactivateProduct", // Action đánh dấu đã bán
          "productId": item['id'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          item['statusCode'] = 4;
          item['status'] = "Đã bán hết";
          _isLoading = false;
        });
        _fetchInventoryFromAPI(); // Lưu lại sau khi cập nhật
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xác nhận bán thành công!"),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _fetchInventoryFromAPI() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/retailer-products'),
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

  // UI DIALOG NHẬP GIÁ
  void _showUpdateShelfInfo(BuildContext context, Map<String, dynamic> item) {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật giá bán"),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Giá bán lẻ (VNĐ)",
            suffixText: "đ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (priceController.text.isNotEmpty) {
                _updateShelf(item, priceController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kRetailerColor),
            child: const Text("Lên Kệ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // UI DIALOG XÁC NHẬN BÁN
  void _showSellDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận bán hàng"),
        content: Text("Bạn xác nhận lô hàng ${item['name']} đã bán hết?"),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản Lý Siêu Thị",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "WinMart - Chi nhánh 1",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),

      // NÚT QUÉT
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanToImport,
        backgroundColor: kRetailerColor,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
    if (timestamp == 0) return "N/A";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.hour}:${date.minute} - ${date.day}/${date.month}/${date.year}";
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    int status = item['statusCode'];
    Color statusColor = status == 2
        ? Colors.orange
        : (status == 3 ? Colors.green : Colors.grey);
    int time = item['time'] ?? 0;
    String arrivalTime = item['time'] != null
        ? _formatDate(item['time'])
        : "Vừa tới";
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
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // NÚT HÀNH ĐỘNG
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
            ],
          ],
        ),
      ),
    );
  }
}
