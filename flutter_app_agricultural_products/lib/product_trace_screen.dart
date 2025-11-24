import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Nhớ chạy: flutter pub add intl
import 'dart:async';

class ProductTraceScreen extends StatefulWidget {
  final String productId; // Nhận ID từ màn hình quét QR

  const ProductTraceScreen({super.key, required this.productId});

  @override
  State<ProductTraceScreen> createState() => _ProductTraceScreenState();
}

class _ProductTraceScreenState extends State<ProductTraceScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchTraceData();
  }

  // Gọi API lấy chi tiết sản phẩm (Public)
  Future<void> _fetchTraceData() async {
    try {
      // Dùng IP máy thật hoặc 10.0.2.2 nếu chạy giả lập
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/${widget.productId}'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _data = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              "Không tìm thấy thông tin sản phẩm trên Blockchain.\nVui lòng kiểm tra lại mã QR.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Lỗi kết nối: $e";
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) return "Đang cập nhật...";
    // Timestamp từ blockchain thường là giây, cần nhân 1000 để ra mili-giây
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Truy Xuất Nguồn Gốc"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final dates = _data!['dates'];
    final images = _data!['images'];
    final farm = _data!['farm'];
    final careLogs = _data!['careLogs'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER SẢN PHẨM
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      images['planting'] ?? '',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _data!['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Mã lô: ${widget.productId.length > 15 ? widget.productId.substring(0, 15) + '...' : widget.productId}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            "NHẬT KÝ HÀNH TRÌNH",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // 2. TIMELINE (DÒNG THỜI GIAN)

          // BƯỚC 1: GIEO TRỒNG (Luôn có)
          _buildTimelineItem(
            title: "Gieo trồng & Khởi tạo",
            time: _formatDate(dates['planting']),
            description:
                "Nông trại: ${farm['name']}\nChủ hộ: ${farm['owner']}\nGiống: ${farm['seed']}",
            icon: Icons.grass,
            color: Colors.green,
            isFirst: true,
          ),

          // BƯỚC 2: CHĂM SÓC (Vòng lặp)
          ...careLogs.map(
            (log) => _buildTimelineItem(
              title: "Chăm sóc: ${log['type']}",
              time: _formatDate(log['date']),
              description: log['desc'],
              imageUrl: log['image'],
              icon: Icons.water_drop,
              color: Colors.teal,
            ),
          ),

          // BƯỚC 3: THU HOẠCH (Nếu có)
          if (dates['harvest'] > 0)
            _buildTimelineItem(
              title: "Thu Hoạch",
              time: _formatDate(dates['harvest']),
              description: "Sản phẩm đã được thu hoạch và đóng gói tại vườn.",
              imageUrl: images['harvest'],
              icon: Icons.agriculture,
              color: Colors.orange,
            ),

          // BƯỚC 4: VẬN CHUYỂN (Nếu có)
          if (dates['receive'] > 0)
            _buildTimelineItem(
              title: "Vận Chuyển",
              time: _formatDate(dates['receive']),
              description:
                  "Đơn vị vận chuyển: ${_data!['transporter']['name'] ?? 'Đang cập nhật'}",
              imageUrl: images['receive'],
              icon: Icons.local_shipping,
              color: Colors.blue,
            ),

          // BƯỚC 5: LÊN KỆ (Nếu có)
          if (_data!['retailer']['price'] > 0 ||
              _data!['dates']['delivery'] > 0)
            _buildTimelineItem(
              title: "Đã Giao Hàng / Lên Kệ",
              // Nếu chưa có ngày delivery thì lấy ngày hiện tại hoặc để trống
              time: _formatDate(
                _data!['dates']['delivery'] > 0
                    ? _data!['dates']['delivery']
                    : 0,
              ),
              description:
                  "Sản phẩm đã có mặt tại điểm bán.\nGiá niêm yết: ${_data!['retailer']['price'] ?? '...'} đ",
              icon: Icons.storefront,
              color: Colors.purple,
              isLast: true,
              isActive: true, // Luôn sáng
            ),
        ],
      ),
    );
  }

  // Widget vẽ từng nấc thang
  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String description,
    required IconData icon,
    required Color color,
    String? imageUrl,
    bool isFirst = false,
    bool isLast = false,
    bool isActive = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cột Timeline
        Column(
          children: [
            // Đường nối trên (nếu không phải đầu tiên)
            if (!isFirst)
              Container(width: 2, height: 20, color: Colors.grey[300]),

            // Icon tròn
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 20, color: color),
            ),

            // Đường nối dưới (nếu không phải cuối cùng)
            if (!isLast)
              Container(
                width: 2,
                height: imageUrl != null ? 120 : 80,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 15),

        // Nội dung bên phải
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 20.0,
            ), // Khoảng cách giữa các step
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),

                  // Ảnh minh chứng (nếu có)
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const SizedBox(), // Lỗi ảnh thì ẩn đi
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
