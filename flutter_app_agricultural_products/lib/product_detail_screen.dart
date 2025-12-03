import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF00C853);

class ProductDetailScreen extends StatelessWidget {
  // Constructor nhận ID (sau này sẽ dùng để fetch dữ liệu)
  final String? productId;

  const ProductDetailScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Product"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white, // Màu nút back và title
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tên Sản Phẩm
            const Text(
              "WATERMELON",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 15),

            // 2. Ảnh Sản phẩm (Lớn)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/images/fruit.png',
                  ), // Thay bằng ảnh dưa hấu
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Thông số (Giá, Số lượng, Diện tích) - Giống trong ảnh
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _SpecRow(
                    icon: Icons.inventory_2,
                    label: "Amount",
                    value: "100 units",
                  ),
                  Divider(),
                  _SpecRow(
                    icon: Icons.attach_money,
                    label: "Price",
                    value: "10 USD/kg",
                  ),
                  Divider(),
                  _SpecRow(
                    icon: Icons.landscape,
                    label: "Acreage",
                    value: "100 m2",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 4. Mô tả (Description)
            const Text(
              "Description",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Homegrown Watermelon - Sweetness from the Heart.\n\nDưa hấu nhà trồng là niềm tự hào của chúng tôi - một sản phẩm sạch, an toàn chứa đựng tình yêu và sự chăm sóc từ những người nông dân tận tụy.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            // 5. Nút Truy xuất nguồn gốc (QUAN TRỌNG)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Bấm vào đây sẽ hiện Popup mã QR hoặc Timeline
                  _showTraceabilityDialog(context);
                },
                icon: const Icon(Icons.history_edu),
                label: const Text(
                  "Blockchain Traceability",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFE65100,
                  ), // Màu cam đậm giống nút 'General information'
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Hàm hiện Popup QR Code (Giống ảnh cuối cùng bạn gửi)
  void _showTraceabilityDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép cuộn full màn hình
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, // Chiều cao ban đầu 70% màn hình
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh nắm kéo (Handle)
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tiêu đề
              const Row(
                children: [
                  Icon(Icons.history_edu, color: kPrimaryColor),
                  SizedBox(width: 10),
                  Text(
                    "Blockchain Journey",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                "Hành trình minh bạch từ nông trại đến bàn ăn",
                style: TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),

              // PHẦN TIMELINE Ở ĐÂY
              Expanded(
                child: ListView(
                  controller:
                      controller, // Quan trọng để cuộn được trong BottomSheet
                  children: [
                    const SizedBox(height: 20),
                    // Nút xem trên Explorer (Etherscan)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Verify on Blockchain Explorer"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget con để hiển thị dòng thông số (Amount, Price...)
class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
