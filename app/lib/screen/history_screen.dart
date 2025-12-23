import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'product_trace_screen.dart';
import '../utils/utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Màu chủ đạo (Lấy giống Home)
  final Color kPrimaryColor = const Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhẹ làm nổi bật thẻ trắng
      appBar: AppBar(
        title: const Text(
          "Lịch Sử Quét",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Nút xóa tất cả (Chỉ hiện khi có dữ liệu)
          ValueListenableBuilder(
            valueListenable: Hive.box('scan_history').listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: "Xóa tất cả",
                onPressed: () => _confirmDeleteAll(context),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('scan_history').listenable(),
        builder: (context, Box box, widget) {
          // 1. TRƯỜNG HỢP TRỐNG (EMPTY STATE)
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Chưa có lịch sử quét",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Các sản phẩm bạn quét mã QR\nsẽ xuất hiện tại đây.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 2. DANH SÁCH DỮ LIỆU
          // Chuyển sang List và đảo ngược để cái mới nhất lên đầu
          final keys = box.keys.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final item = box.get(key) as Map;
              return _buildHistoryCard(item, key, index);
            },
          );
        },
      ),
    );
  }

  // Widget thẻ lịch sử (Xịn hơn ListTile)
  Widget _buildHistoryCard(Map data, dynamic key, int index) {
    final date = DateTime.parse(data['scannedAt']);
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(date);
    String heroTag = "history_${data['id']}_$index"; // Tag unique

    // Dismissible: Vuốt để xóa
    return Dismissible(
      key: Key(key.toString()),
      direction: DismissDirection.endToStart, // Chỉ vuốt từ phải sang trái
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 30),
            Text(
              "Xóa",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        Hive.box('scan_history').delete(key); // Xóa khỏi Hive
        Utils.showSuccess(
          context,
          "Đã xóa!",
          "Bạn đã xóa sản phẩm '${data['name']}' khỏi lịch sử.",
        );
      },
      child: GestureDetector(
        onTap: () {
          // Chuyển trang xem chi tiết
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductTraceScreen(
                productId: data['id'],
                initialImage: data['image'],
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. ẢNH SẢN PHẨM (BÊN TRÁI)
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child:
                        (data['image'] != null &&
                            data['image'].toString().isNotEmpty)
                        ? Image.network(
                            data['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(Icons.eco, size: 40, color: kPrimaryColor),
                  ),
                ),
              ),

              // 2. THÔNG TIN (BÊN PHẢI)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên sản phẩm
                      Text(
                        data['name'] ?? "Sản phẩm",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Tên nông trại
                      Row(
                        children: [
                          Icon(Icons.store, size: 14, color: kPrimaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['farmName'] ?? "Nông trại",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      const Divider(height: 10, thickness: 0.5),

                      // Ngày giờ quét
                      Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. MŨI TÊN NHỎ
              const Padding(
                padding: EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hộp thoại xác nhận xóa tất cả
  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Xóa lịch sử?"),
          ],
        ),
        content: const Text(
          "Hành động này sẽ xóa toàn bộ lịch sử quét mã trên thiết bị này.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Hive.box('scan_history').clear();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa tất cả"),
          ),
        ],
      ),
    );
  }
}
