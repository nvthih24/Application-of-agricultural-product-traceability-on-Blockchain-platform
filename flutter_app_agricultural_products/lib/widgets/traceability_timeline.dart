import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart'; // Format ngày tháng

class TraceabilityTimeline extends StatelessWidget {
  // Dữ liệu giả lập (Sau này sẽ truyền từ API vào)
  final List<Map<String, dynamic>> steps = [
    {
      "title": "Gieo trồng",
      // Dùng DateFormat để lấy ngày giờ hiện tại
      "time": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      "location": "Pione Farm, Khu A",
      "description": "Bắt đầu xuống giống Cải thìa hữu cơ.",
      "icon": Icons.grass,
      "isCompleted": true,
    },
    {
      "title": "Thu hoạch",
      "time": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      "location": "Pione Farm, Khu A",
      "description": "Thu hoạch đạt tiêu chuẩn VietGAP. Sản lượng 100kg.",
      "icon": Icons.agriculture,
      "isCompleted": true,
    },
    {
      "title": "Vận chuyển",
      "time": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      "location": "Đang trên đường đến kho",
      "description": "Đơn vị vận chuyển: FastShip. Nhiệt độ bảo quản: 25°C",
      "icon": Icons.local_shipping,
      "isCompleted": true,
    },
    {
      "title": "Đến siêu thị",
      "time": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      "location": "Siêu thị BigC",
      "description": "Chưa cập nhật",
      "icon": Icons.storefront,
      "isCompleted": false, // Chưa hoàn thành
    },
  ];

  TraceabilityTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, // Để nhúng vào trong Dialog hoặc Column
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return _buildTimelineTile(step, index == 0, index == steps.length - 1);
      },
    );
  }

  Widget _buildTimelineTile(
    Map<String, dynamic> step,
    bool isFirst,
    bool isLast,
  ) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: step['isCompleted']
            ? const Color(0xFF00C853)
            : Colors.grey.shade300,
        thickness: 3,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            color: step['isCompleted']
                ? const Color(0xFF00C853)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child: Icon(step['icon'], color: Colors.white, size: 20),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  step['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: step['isCompleted'] ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  step['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              step['location'],
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 5),
            Text(
              step['description'],
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
