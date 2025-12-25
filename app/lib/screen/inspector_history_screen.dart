import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'dart:async';

import '../configs/constants.dart';

const Color kInspectorColor = Color(0xFF6A1B9A);
const Color kInspectorLight = Color(0xFF9C4DCC);

class InspectorHistoryTab extends StatefulWidget {
  const InspectorHistoryTab({super.key});

  @override
  State<InspectorHistoryTab> createState() => _InspectorHistoryTabState();
}

class _InspectorHistoryTabState extends State<InspectorHistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> historyPlanting = [];
  List<dynamic> historyHarvest = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/moderated-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          historyPlanting = data['planting'];
          historyHarvest = data['harvest'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhẹ
      appBar: AppBar(
        backgroundColor: kInspectorColor, // Dùng màu tím chủ đạo
        title: const Text(
          "Lịch sử kiểm duyệt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.grass), text: "Gieo Trồng"),
            Tab(icon: Icon(Icons.inventory), text: "Thu Hoạch"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kInspectorColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(
                  historyPlanting,
                  "Chưa có lịch sử gieo trồng.",
                ),
                _buildHistoryList(historyHarvest, "Chưa có lịch sử thu hoạch."),
              ],
            ),
    );
  }

  Widget _buildHistoryList(List<dynamic> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildHistoryCard(items[i]),
    );
  }

  // Widget Card Đẹp (Đồng bộ với Dashboard)
  Widget _buildHistoryCard(dynamic item) {
    bool isApproved = item['statusCode'] == 1; // 1: Approved, 2: Rejected
    Color statusColor = isApproved ? Colors.green : Colors.red;
    String statusText = isApproved ? "Đã Chấp Thuận" : "Đã Từ Chối";
    IconData statusIcon = isApproved ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Ảnh sản phẩm
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Thông tin
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
                      const SizedBox(height: 4),
                      Text(
                        "Farm: ${item['farm']}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${item['id']}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Hàng trạng thái & Ngày tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ngày xử lý (Nếu có timestamp thì format, ko thì hiện N/A)
                Text(
                  _formatDate(item['date']), // Hàm format date dùng chung
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
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }
}
