import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_scanner_screen.dart';
import 'package:image_picker/image_picker.dart'; // Nhớ import để chụp ảnh kệ
// import 'package:mime/mime.dart'; // Cần thêm logic upload ảnh nếu muốn full
import 'home_screen.dart';

const Color kRetailerColor = Colors.indigo;

class RetailerMainScreen extends StatefulWidget {
  const RetailerMainScreen({super.key});

  @override
  State<RetailerMainScreen> createState() => _RetailerMainScreenState();
}

class _RetailerMainScreenState extends State<RetailerMainScreen> {
  // Danh sách sản phẩm ĐANG QUẢN LÝ (Lưu tạm trên máy hoặc gọi API nếu có)
  // Demo: Sẽ load các sản phẩm vừa quét được
  List<Map<String, dynamic>> myInventory = [];
  bool _isLoading = false;

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

  // 1. HÀM QUÉT MÃ NHẬP KHO
  Future<void> _scanToImport() async {
    // Mở màn hình quét QR, chờ kết quả trả về là mã ProductID
    /* LƯU Ý: Ông cần sửa lại qr_scanner_screen.dart một chút để nó support trả về dữ liệu 
       thay vì tự push sang trang Trace.
       Hoặc đơn giản là copy file qr_scanner cũ, đổi tên thành qr_picker.dart để dùng cho việc này.
       Ở đây tôi giả định hàm Navigator.push trả về String code.
    */
    // Tạm thời dùng code cứng để test luồng trước nhé, sau ông gắn QR sau.
    // String? code = await Navigator.push(...);

    // Giả lập quét được mã:
    String code = "BATCH-1763967012955-246"; // Thay bằng mã thật ông vừa tạo
    _fetchProductInfoToAdd(code);
  }

  // Lấy thông tin sản phẩm từ Blockchain để hiện lên list
  Future<void> _fetchProductInfoToAdd(String productId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/$productId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        // Kiểm tra xem đã có trong list chưa
        if (myInventory.any((e) => e['id'] == productId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sản phẩm này đã có trong danh sách!"),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        setState(() {
          myInventory.add({
            "id": data['id'],
            "name": data['name'],
            "farm": data['farm']['name'],
            "image": data['images']['planting'], // Lấy tạm ảnh planting
            "price": data['retailer']['price'] > 0
                ? "${data['retailer']['price']}"
                : "",
            "statusCode": data['dates']['delivery'] > 0
                ? 3
                : 2, // 2: Mới nhận, 3: Đã lên kệ
            "status": data['dates']['delivery'] > 0
                ? "Đang bày bán"
                : "Chờ lên kệ",
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  // 2. HÀM CẬP NHẬT GIÁ & LÊN KỆ (GỌI TRANSACTION)
  Future<void> _updateShelf(Map<String, dynamic> item, String price) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Ở đây thiếu bước upload ảnh kệ hàng, ông có thể copy logic từ add_crop_screen qua
      // Tạm thời gửi ảnh rỗng hoặc ảnh cũ

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "updateManagerInfo",
          "productId": item['id'].toString().trim(),
          "managerReceiveDate": (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          "managerReceiveImageUrl": "", // TODO: Thêm logic upload ảnh
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lên kệ thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // --- THÊM ĐOẠN NÀY VÀO ĐỂ TẮT QUAY KHI LỖI ---
        setState(() => _isLoading = false);
        // In lỗi ra để biết tại sao
        print("Lỗi Backend: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }

  // 3. HÀM XÁC NHẬN BÁN (DEACTIVATE)
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // UI Dialog nhập giá
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
            labelText: "Giá bán (VNĐ)",
            suffixText: "đ",
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
      appBar: AppBar(
        backgroundColor: kRetailerColor,
        title: const Text(
          "Quản Lý Siêu Thị",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Tạm thời gọi hàm giả lập quét mã để test
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
          ? const Center(child: Text("Kho trống. Hãy quét mã để nhập hàng."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: myInventory.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(myInventory[index]),
            ),
    );
  }

  // Widget Card (Giữ nguyên logic UI hôm qua, chỉ đổi data)
  Widget _buildProductCard(Map<String, dynamic> item) {
    // ... (Copy lại đoạn build Card hôm qua vào đây, thay các biến item['...'] tương ứng)
    // Nếu ông lười thì bảo tôi, tôi paste nốt đoạn này cho.
    // Nhưng cơ bản là giống hệt file hôm qua.
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Image.network(
          item['image'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image),
        ),
        title: Text(
          item['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${item['id']}", style: const TextStyle(fontSize: 10)),
            Text(
              "Trạng thái: ${item['status']}",
              style: TextStyle(
                color: item['statusCode'] == 3 ? Colors.green : Colors.orange,
              ),
            ),
            if (item['price'] != "")
              Text(
                "Giá: ${item['price']} đ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: item['statusCode'] == 2
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showUpdateShelfInfo(context, item),
              )
            : item['statusCode'] == 3
            ? IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _soldProduct(item),
              )
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}
