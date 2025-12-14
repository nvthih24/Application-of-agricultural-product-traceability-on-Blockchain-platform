import 'package:flutter/material.dart';

import 'qr_scanner_screen.dart';

import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await HistoryService.getHistory();
    setState(() {
      _historyList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Lịch sử truy xuất"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Nút xóa tất cả
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: () {
                _confirmDeleteAll();
              },
            ),
        ],
      ),
      body: _historyList.isEmpty
          ? _buildEmptyState() // Hiện cái này nếu không có dữ liệu
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];
                return _buildHistoryItem(item, index);
              },
            ),
    );
  }

  // Widget hiển thị khi danh sách trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off,
              size: 80,
              color: Colors.green[300],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Bạn chưa quét sản phẩm nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Hãy thử quét mã QR trên sản phẩm\nđể kiểm tra nguồn gốc nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Quét Ngay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget từng dòng lịch sử (Có chức năng vuốt xóa)
  Widget _buildHistoryItem(Map<String, dynamic> item, int index) {
    // Xác định màu sắc dựa trên trạng thái
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (item['status'] == 1) {
      statusColor = Colors.green;
      statusText = "Chính hãng";
      statusIcon = Icons.verified_user;
    } else if (item['status'] == 0) {
      statusColor = Colors.red;
      statusText = "Cảnh báo";
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.orange;
      statusText = "Chưa rõ";
      statusIcon = Icons.help_outline;
    }

    return Dismissible(
      key: Key(item['id'] + index.toString()),
      direction: DismissDirection.endToStart, // Chỉ vuốt từ phải sang trái
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 30),
      ),
      onDismissed: (direction) {
        setState(() {
          _historyList.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xóa khỏi lịch sử"),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item['image'].toString().isNotEmpty
                ? Image.network(
                    item['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : Container(
                    color: Colors.grey[100],
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.qr_code, color: Colors.grey),
                  ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.storefront, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item['farm'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item['time'],
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () {
            // Sau này mở lại trang chi tiết sản phẩm
            // Navigator.push(...);
          },
        ),
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tất cả?"),
        content: const Text(
          "Bạn có chắc muốn xóa toàn bộ lịch sử truy xuất không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await HistoryService.clearHistory();
              setState(() {
                _historyList.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
