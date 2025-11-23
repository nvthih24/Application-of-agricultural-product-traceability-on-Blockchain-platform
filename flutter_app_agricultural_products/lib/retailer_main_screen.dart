import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

const Color kRetailerColor = Colors.indigo;

class RetailerMainScreen extends StatefulWidget {
  const RetailerMainScreen({super.key});

  @override
  State<RetailerMainScreen> createState() => _RetailerMainScreenState();
}

class _RetailerMainScreenState extends State<RetailerMainScreen> {
  // Dữ liệu giả lập (Mô phỏng quy trình tại siêu thị)
  // statusCode:
  // 2: Đã giao (Hàng vừa tới kho, chờ nhập)
  // 3: Đang bày bán (Đã cập nhật giá/ảnh)
  // 4: Đã bán (Sold out)
  final List<Map<String, dynamic>> myInventory = [
    {
      "id": "DUAHAU-BATCH-088",
      "name": "Dưa hấu Long An",
      "farm": "3TML Farm",
      "price": "Chưa cập nhật",
      "image": "assets/images/fruit.png",
      "statusCode": 2, // Hàng mới tới -> Cần nút "Lên kệ"
      "status": "Chờ lên kệ",
    },
    {
      "id": "CAITHIA-BATCH-001",
      "name": "Cải thìa hữu cơ",
      "farm": "3TML Farm",
      "price": "25.000 đ/kg",
      "image": "assets/images/farm_1.jpg",
      "statusCode": 3, // Đang bán -> Cần nút "Xác nhận bán"
      "status": "Đang bày bán",
    },
    {
      "id": "LUA-BATCH-99",
      "name": "Gạo ST25",
      "farm": "Nông trại B",
      "price": "180.000 đ/túi",
      "image": "assets/images/lua.jpg",
      "statusCode": 4, // Đã bán -> Chỉ xem
      "status": "Đã bán hết",
    },
  ];

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

  // Hộp thoại cập nhật thông tin bán hàng (Giá + Ảnh quầy)
  void _showUpdateShelfInfo(BuildContext context, Map<String, dynamic> item) {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật thông tin bày bán"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nhập giá bán và ảnh tại quầy kệ để khách hàng tra cứu.",
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Giá bán (VNĐ)",
                border: OutlineInputBorder(),
                suffixText: "đ",
                prefixIcon: Icon(Icons.price_change),
              ),
            ),
            const SizedBox(height: 10),
            // Demo nút chụp ảnh (giả lập)
            InkWell(
              onTap: () {
                /* Logic chụp ảnh */
              },
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey),
                    Text("Chụp ảnh quầy hàng"),
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
            onPressed: () {
              // GỌI API updateManagerInfo TẠI ĐÂY
              Navigator.pop(context);
              setState(() {
                item['statusCode'] = 3;
                item['status'] = "Đang bày bán";
                item['price'] = "${priceController.text} đ";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã lên kệ thành công!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kRetailerColor),
            child: const Text("Lên Kệ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hộp thoại xác nhận bán hàng
  void _showSellDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận bán hàng"),
        content: Text(
          "Xác nhận lô hàng ${item['name']} đã được bán hết cho người tiêu dùng?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                item['statusCode'] = 4;
                item['status'] = "Đã bán hết";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã cập nhật trạng thái: Đã bán!"),
                ),
              );
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: kRetailerColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản Lý Siêu Thị",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "WinMart - Chi nhánh 1",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      // NÚT QUÉT MÃ NHẬP KHO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
          );
        },
        backgroundColor: kRetailerColor,
        icon: const Icon(Icons.qr_code_2, color: Colors.white),
        label: const Text(
          "Quét Nhập Kho",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: myInventory.length,
        itemBuilder: (context, index) {
          return _buildProductCard(myInventory[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    int status = item['statusCode'];
    Color statusColor = status == 2
        ? Colors.orange
        : (status == 3 ? Colors.green : Colors.grey);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Thông tin cơ bản
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.store),
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
                        "Nguồn: ${item['farm']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['price'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 3 ? Colors.red : Colors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Nút Hành Động
            if (status == 2) ...[
              // Hàng mới tới -> Cần lên kệ
              const SizedBox(height: 12),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateShelfInfo(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRetailerColor,
                  ),
                  icon: const Icon(Icons.shelves, color: Colors.white),
                  label: const Text(
                    "Cập nhật & Lên kệ",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],

            if (status == 3) ...[
              // Đang bán -> Xác nhận bán xong
              const SizedBox(height: 12),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSellDialog(context, item),
                  icon: const Icon(Icons.sell, color: Colors.green),
                  label: const Text(
                    "Xác nhận đã bán",
                    style: TextStyle(color: Colors.green),
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
