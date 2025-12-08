import 'package:flutter/material.dart';

const Color kDistributorColor = Color(0xFF673AB7); // Màu Tím (Thương mại)

class DistributorMainScreen extends StatefulWidget {
  const DistributorMainScreen({super.key});

  @override
  State<DistributorMainScreen> createState() => _DistributorMainScreenState();
}

class _DistributorMainScreenState extends State<DistributorMainScreen> {
  // Hàm giả lập sau khi quét xong
  void _onScanSuccess(String productId) {
    // Hiện dialog nhập giá
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nhập kho: $productId"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Sản phẩm: Dưa hấu Long An"),
            const SizedBox(height: 15),
            const TextField(
              decoration: InputDecoration(
                labelText: "Giá bán lẻ (VNĐ)",
                suffixText: "đ",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            // Nút chụp ảnh trưng bày (Placeholder)
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
              label: const Text("Chụp ảnh tại quầy"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã cập nhật giá bán thành công!"),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kDistributorColor),
            child: const Text(
              "XÁC NHẬN",
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
        title: const Text(
          "Nhà Phân Phối",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kDistributorColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Giả lập quét thành công luôn để test giao diện
                _onScanSuccess("DUAHAU-088");
                // Thực tế sẽ gọi: Navigator.push(context, MaterialPageRoute(builder: (c) => QrScannerScreen()));
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: kDistributorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: kDistributorColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quét sản phẩm để nhập giá",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
