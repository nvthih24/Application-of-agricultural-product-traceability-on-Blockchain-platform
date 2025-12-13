import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:convert';

import '../configs/constants.dart';

class ProductTraceScreen extends StatefulWidget {
  final String productId;

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

  Future<void> _fetchTraceData() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/${widget.productId}'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _data = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Không tìm thấy dữ liệu sản phẩm.";
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
    if (timestamp == null || timestamp == 0) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hồ Sơ Truy Xuất"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(_error),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Safe Access Data
    final farm = _data!['farm'] ?? {};
    final dates = _data!['dates'] ?? {};
    final images = _data!['images'] ?? {};
    final transporter = _data!['transporter'] ?? {};
    final retailer = _data!['retailer'] ?? {};
    final careLogs = (_data!['careLogs'] as List?) ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. HEADER INFO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(images['planting'] ?? ''),
                    onBackgroundImageError: (_, __) => const Icon(Icons.image),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _data!['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ID: ${widget.productId}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Căn giữa
                    maxLines: 1, // Chỉ hiện 1 dòng
                    overflow:
                        TextOverflow.ellipsis, // Nếu dài quá thì hiện "..."
                  ),
                ),
              ],
            ),
          ),

          // 2. TIMELINE CHI TIẾT
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NHẬT KÝ MINH BẠCH",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                // --- GIAI ĐOẠN 1: GIEO TRỒNG ---
                _buildTimelineItem(
                  title: "Khởi tạo & Gieo trồng",
                  time: _formatDate(dates['planting']),
                  icon: Icons.eco,
                  color: Colors.green,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.store, "Nông trại:", farm['name']),
                      _buildInfoRow(Icons.person, "Chủ hộ:", farm['owner']),
                      // THÔNG TIN QUAN TRỌNG: Nguồn giống
                      _buildInfoRow(
                        Icons.local_florist,
                        "Nguồn giống:",
                        farm['seed'] ?? "Đang cập nhật",
                      ),
                      if (images['planting'] != "")
                        _buildImagePreview(images['planting']),
                    ],
                  ),
                  isFirst: true,
                ),

                // --- GIAI ĐOẠN 2: CHĂM SÓC ---
                ...careLogs.map(
                  (log) => _buildTimelineItem(
                    title: "Chăm sóc: ${log['type']}",
                    time: _formatDate(log['date']),
                    icon: Icons.water_drop,
                    color: Colors.teal,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['desc'],
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        if (log['image'] != "")
                          _buildImagePreview(log['image']),
                      ],
                    ),
                    isSmall: true,
                  ),
                ),

                // --- GIAI ĐOẠN 3: THU HOẠCH ---
                if (dates['harvest'] > 0)
                  _buildTimelineItem(
                    title: "Thu Hoạch & Đóng Gói",
                    time: _formatDate(dates['harvest']),
                    icon: Icons.agriculture,
                    color: Colors.orange,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // THÔNG TIN QUAN TRỌNG: Sản lượng & Chất lượng
                        // (Lấy từ _data root nếu backend có trả về, hoặc hiển thị mẫu)
                        _buildInfoRow(
                          Icons.scale,
                          "Sản lượng:",
                          // Nếu null thì hiện "Đang cập nhật"
                          (_data!['harvestInfo'] != null)
                              ? _data!['harvestInfo']['quantity']
                              : "Đang cập nhật",
                        ),
                        _buildInfoRow(
                          Icons.grade,
                          "Chất lượng:",
                          // Nếu null thì hiện "Đang cập nhật"
                          (_data!['harvestInfo'] != null)
                              ? _data!['harvestInfo']['quality']
                              : "Đang kiểm định",
                        ),
                        if (images['harvest'] != "")
                          _buildImagePreview(images['harvest']),
                      ],
                    ),
                  ),

                // --- STEP 4A: BẮT ĐẦU VẬN CHUYỂN (PICKUP) ---
                if (dates['receive'] > 0)
                  _buildTimelineItem(
                    title: "Đã Nhận Hàng & Vận Chuyển",
                    time: _formatDate(dates['receive']),
                    icon: Icons.local_shipping, // Icon xe tải
                    color: Colors.blue,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.business,
                          "Đơn vị:",
                          transporter['name'] ?? "Ẩn danh",
                        ),
                        _buildInfoRow(
                          Icons.directions_car,
                          "Phương tiện:",
                          transporter['info'] ?? "Xe chuyên dụng",
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Đã bốc hàng lên xe và bắt đầu di chuyển.",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),

                        // Ảnh lúc nhận (Nếu có)
                        if (images['receive'] != null &&
                            images['receive'].toString().isNotEmpty)
                          _buildEvidenceImage(
                            "Ảnh lúc nhận hàng",
                            images['receive'],
                          ),
                      ],
                    ),
                    isActive: true,
                  ),

                // --- STEP 4B: GIAO HÀNG THÀNH CÔNG (DELIVERY) ---
                if (dates['delivery'] > 0)
                  _buildTimelineItem(
                    title: "Giao Hàng Thành Công",
                    time: _formatDate(dates['delivery']),
                    icon: Icons.check_circle, // Icon check xanh
                    color: Colors.blue[800]!, // Màu xanh đậm hơn chút
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Đã vận chuyển an toàn đến điểm tập kết/siêu thị.",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),

                        // Ảnh lúc giao (Nếu có)
                        if (images['delivery'] != null &&
                            images['delivery'].toString().isNotEmpty)
                          _buildEvidenceImage(
                            "Ảnh tại điểm giao",
                            images['delivery'],
                          ),
                      ],
                    ),
                    isActive: true,
                  ),

                // --- GIAI ĐOẠN 5: TIÊU THỤ ---
                if (retailer['price'] > 0 || dates['delivery'] > 0)
                  _buildTimelineItem(
                    title: "Phân Phối & Tiêu Dùng",
                    time: _formatDate(
                      dates['delivery'] > 0
                          ? dates['delivery']
                          : dates['receive'],
                    ),
                    icon: Icons.storefront,
                    color: Colors.purple,
                    isLast: true,
                    isActive: true,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sản phẩm đã được kiểm định và lên kệ.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),

                        // 1. HIỂN THỊ GIÁ BÁN
                        if (retailer['price'] > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.price_check,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${retailer['price']} VNĐ",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        // 2. HIỂN THỊ ẢNH QUẦY KỆ (MỚI THÊM) 🔥
                        if (retailer['image'] != null &&
                            retailer['image'].toString().isNotEmpty) ...[
                          _buildEvidenceImage(
                            "Ảnh trưng bày thực tế",
                            retailer['image'],
                          ),
                          const SizedBox(height: 15),
                        ],

                        // 3. Nút Blockchain
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              launchUrl(
                                Uri.parse("https://zeroscan.org"),
                              ); // Link demo
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text("Xác thực trên Blockchain"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                            ),
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
    );
  }

  // Widget hiển thị 1 dòng thông tin nhỏ (Icon + Label + Value)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị ảnh nhỏ trong timeline
  Widget _buildImagePreview(String? url) {
    if (url == null || url.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Cách 1: Ẩn luôn nếu lỗi
            return const SizedBox();

            // Cách 2 (Nếu muốn hiện ảnh thế chỗ):
            // return Container(
            //    height: 100,
            //    color: Colors.grey[200],
            //    child: Icon(Icons.image_not_supported, color: Colors.grey)
            // );
          },
        ),
      ),
    );
  }

  // Widget vẽ khung Timeline
  Widget _buildTimelineItem({
    required String title,
    required String time,
    String description = "", // Mặc định rỗng nếu không truyền
    required IconData icon,
    required Color color,
    Widget? content, // Cho phép truyền widget con (như danh sách info)
    String? imageUrl, // Ảnh minh chứng (nếu có)
    bool isFirst = false,
    bool isLast = false,
    bool isActive = true,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CỘT TIMELINE (BÊN TRÁI)
        Column(
          children: [
            // Dây nối trên
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isActive ? color.withOpacity(0.5) : Colors.grey[300],
              ),

            // Icon tròn
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 10),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? color : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: isSmall ? 16 : 20,
                color: isActive ? color : Colors.grey,
              ),
            ),

            // Dây nối dưới (tự động dài ra nếu nội dung dài)
            if (!isLast)
              Container(
                width: 2,
                height: 100, // Chiều cao tương đối, có thể chỉnh
                color: isActive ? color.withOpacity(0.5) : Colors.grey[300],
              ),
          ],
        ),

        const SizedBox(width: 15), // Khoảng cách giữa cột và Card
        // NỘI DUNG (BÊN PHẢI)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của Card (Title + Time)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive ? color : Colors.grey,
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const Divider(height: 15),

                    // Nội dung chi tiết (Text Description hoặc Widget Content tùy chọn)
                    if (content != null)
                      content
                    else
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),

                    // Ảnh minh chứng (Nếu có)
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget hiển thị ảnh bằng chứng nhỏ có chú thích
  Widget _buildEvidenceImage(String label, String? url) {
    // 1. NẾU KHÔNG CÓ ẢNH (Đơn hàng cũ) -> Hiện Placeholder
    if (url == null || url.isEmpty || url == "null") {
      return Column(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200], // Nền xám
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
                SizedBox(height: 4),
                Text(
                  "Chưa có ảnh",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // 2. NẾU CÓ ẢNH (Đơn hàng mới) -> Hiện ảnh bình thường
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 80,
            width: double.infinity,
            fit: BoxFit.cover,
            // Nếu link ảnh bị chết (404) thì cũng hiện icon lỗi
            errorBuilder: (c, e, s) => Container(
              height: 80,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
