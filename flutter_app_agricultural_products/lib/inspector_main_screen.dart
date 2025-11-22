import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

const Color kInspectorColor = Color(0xFF795548); // Màu Nâu (Quản lý/Đất)

class InspectorMainScreen extends StatefulWidget {
  const InspectorMainScreen({super.key});

  @override
  State<InspectorMainScreen> createState() => _InspectorMainScreenState();
}

class _InspectorMainScreenState extends State<InspectorMainScreen> {
  // Dữ liệu giả lập (Sau này lấy từ API: /api/pending-requests)
  final List<Map<String, dynamic>> pendingRequests = [
    {
      "id": "CAITHIA-001",
      "farmer": "Nguyễn Văn A",
      "action": "Yêu cầu Gieo trồng",
      "productName": "Cải thìa hữu cơ",
      "time": "10:30 AM, 22/11/2025",
      "status": "pending_planting"
    },
    {
      "id": "DUAHAU-088",
      "farmer": "Trần Văn B",
      "action": "Yêu cầu Thu hoạch",
      "productName": "Dưa hấu Long An",
      "time": "08:15 AM, 22/11/2025",
      "status": "pending_harvest"
    },
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: kInspectorColor,
        title: const Text("Kiểm Duyệt Nông Trại", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          final item = pendingRequests[index];
          return _buildRequestCard(item);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    bool isPlanting = item['status'] == 'pending_planting';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Loại yêu cầu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPlanting ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPlanting ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    item['action'],
                    style: TextStyle(
                      color: isPlanting ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold, fontSize: 12
                    ),
                  ),
                ),
                Text(item['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            
            // Nội dung
            Text(item['productName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Nông dân: ${item['farmer']}", style: const TextStyle(fontSize: 14)),
            Text("Mã ID: ${item['id']}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            
            const Divider(height: 25),

            // Nút Duyệt / Từ chối
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { /* Gọi API Từ chối */ },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text("Từ chối"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { /* Gọi API Duyệt (Approve) */ },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("DUYỆT NGAY"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}