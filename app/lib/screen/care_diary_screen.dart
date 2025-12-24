import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

// Model dữ liệu cho 1 dòng nhật ký
class DiaryLog {
  final String title; // Tiêu đề (VD: Bón phân đợt 1)
  final String description; // Chi tiết (VD: Dùng phân NPK...)
  final DateTime date; // Ngày thực hiện
  final String
  type; // Loại: 'water', 'fertilizer', 'pesticide', 'harvest', 'other'
  final String? imageUrl; // Ảnh minh chứng (nếu có)

  DiaryLog({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.imageUrl,
  });
}

class CareDiaryScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const CareDiaryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<CareDiaryScreen> createState() => _CareDiaryScreenState();
}

class _CareDiaryScreenState extends State<CareDiaryScreen> {
  // Dữ liệu giả lập (Sau này lấy từ API về)
  final List<DiaryLog> _logs = [
    DiaryLog(
      title: "Xuống giống",
      description: "Gieo hạt giống F1, mật độ 20cm/cây. Thời tiết mát mẻ.",
      date: DateTime.now().subtract(const Duration(days: 10)),
      type: "other",
    ),
    DiaryLog(
      title: "Tưới nước tự động",
      description: "Hệ thống tưới nhỏ giọt hoạt động 30 phút.",
      date: DateTime.now().subtract(const Duration(days: 8)),
      type: "water",
    ),
    DiaryLog(
      title: "Bón lót đợt 1",
      description: "Sử dụng phân hữu cơ vi sinh, 50kg/sào.",
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: "fertilizer",
    ),
    DiaryLog(
      title: "Phòng trừ sâu bệnh",
      description: "Phát hiện sâu cuốn lá nhỏ, phun chế phẩm sinh học.",
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: "pesticide",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Sắp xếp nhật ký: Mới nhất lên đầu
    _logs.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nhật Ký Canh Tác", style: TextStyle(fontSize: 18)),
            Text(
              widget.productName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),

      // Nút thêm nhật ký mới
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogDialog,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.edit_calendar, color: Colors.white),
        label: const Text("Ghi Nhật Ký", style: TextStyle(color: Colors.white)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return _buildTimelineTile(
              log,
              index == 0,
              index == _logs.length - 1,
            );
          },
        ),
      ),
    );
  }

  // Widget vẽ từng dòng Timeline
  Widget _buildTimelineTile(DiaryLog log, bool isFirst, bool isLast) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(color: Colors.green.shade200, thickness: 2),
      afterLineStyle: LineStyle(color: Colors.green.shade200, thickness: 2),
      indicatorStyle: IndicatorStyle(
        width: 35,
        height: 35,
        indicator: Container(
          decoration: BoxDecoration(
            color: _getTypeColor(log.type),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4),
            ],
          ),
          child: Icon(_getTypeIcon(log.type), color: Colors.white, size: 18),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ngày tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(log.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 8),

            // Tiêu đề
            Text(
              log.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            const SizedBox(height: 5),

            // Nội dung
            Text(
              log.description,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),

            // Nếu có ảnh thì hiện ở đây
            if (log.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  log.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Chọn màu theo loại hoạt động
  Color _getTypeColor(String type) {
    switch (type) {
      case 'water':
        return Colors.blue;
      case 'fertilizer':
        return Colors.orange;
      case 'pesticide':
        return Colors.redAccent;
      case 'harvest':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  // Chọn icon theo loại hoạt động
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'fertilizer':
        return Icons.science; // Hoặc icon cái bao phân
      case 'pesticide':
        return Icons.bug_report;
      case 'harvest':
        return Icons.agriculture;
      default:
        return Icons.eco;
    }
  }

  // Hộp thoại thêm nhật ký mới
  void _showAddLogDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'water';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để đẩy lên khi có bàn phím
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ghi Hoạt Động Mới",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Chọn loại hoạt động
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChoiceChip(
                      "Tưới nước",
                      'water',
                      selectedType,
                      (val) => setModalState(() => selectedType = val),
                    ),
                    _buildChoiceChip(
                      "Bón phân",
                      'fertilizer',
                      selectedType,
                      (val) => setModalState(() => selectedType = val),
                    ),
                    _buildChoiceChip(
                      "Phun thuốc",
                      'pesticide',
                      selectedType,
                      (val) => setModalState(() => selectedType = val),
                    ),
                    _buildChoiceChip(
                      "Khác",
                      'other',
                      selectedType,
                      (val) => setModalState(() => selectedType = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Tiêu đề (VD: Bón NPK)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Chi tiết công việc",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      // Thêm vào danh sách và cập nhật UI
                      setState(() {
                        _logs.add(
                          DiaryLog(
                            title: titleController.text,
                            description: descController.text,
                            date: DateTime.now(),
                            type: selectedType,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                  child: const Text(
                    "LƯU NHẬT KÝ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String groupValue,
    Function(String) onSelect,
  ) {
    bool isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.green[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.green[800] : Colors.black,
        ),
        onSelected: (selected) {
          if (selected) onSelect(value);
        },
      ),
    );
  }
}
