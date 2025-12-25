import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import '../configs/constants.dart';

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
  bool _isLoading = true;
  List<dynamic> _logs = []; // Dữ liệu thật từ Server

  // Controller nhập liệu
  final _descController = TextEditingController();
  String _selectedAction = "Tưới nước";
  File? _evidenceImage;

  final List<String> _actions = [
    "Tưới nước",
    "Bón phân",
    "Phun thuốc",
    "Tỉa cành",
    "Kiểm tra sâu bệnh",
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // 1. TẢI NHẬT KÝ TỪ SERVER (Dữ liệu thật)
  Future<void> _loadLogs() async {
    try {
      // Gọi API lấy chi tiết sản phẩm để lấy careLogs
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/${widget.productId}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend trả về field 'careLogs' (như đã sửa ở Bước 1)
        if (data['success'] == true && data['data']['careLogs'] != null) {
          setState(() {
            _logs = List.from(
              data['data']['careLogs'],
            ).reversed.toList(); // Mới nhất lên đầu
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      print("Lỗi tải nhật ký: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. CHỤP ẢNH MINH CHỨNG
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _evidenceImage = File(pickedFile.path);
      });
    }
  }

  // 3. UPLOAD ẢNH LÊN SERVER
  Future<String?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/upload/image'),
      );
      final mimeType = lookupMimeType(image.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        return jsonDecode(resStr)['url'];
      }
    } catch (e) {
      print("Lỗi upload ảnh: $e");
    }
    return null;
  }

  // 4. GỬI NHẬT KÝ LÊN BLOCKCHAIN & DB
  Future<void> _submitLog() async {
    if (_evidenceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chụp ảnh minh chứng!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Đóng dialog nhập liệu

    try {
      // B1: Upload ảnh
      String? imageUrl = await _uploadImage(_evidenceImage!);
      if (imageUrl == null) throw Exception("Upload ảnh thất bại");

      // B2: Gọi API Transaction
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "logCare",
          "productId": widget.productId,
          "careType": _selectedAction,
          "description": _descController.text,
          "careDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "careImageUrl": imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã thêm nhật ký thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        _descController.clear();
        _evidenceImage = null;
        // Đợi 2s cho Server đồng bộ rồi tải lại
        await Future.delayed(const Duration(seconds: 2));
        _loadLogs();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  // UI: HIỂN THỊ DIALOG THÊM MỚI
  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thêm Nhật Ký Chăm Sóc",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedAction,
                items: _actions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setModalState(() => _selectedAction = val!),
                decoration: const InputDecoration(
                  labelText: "Hoạt động",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Ghi chú chi tiết",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 15),

              // KHUNG CHỤP ẢNH
              InkWell(
                onTap: () async {
                  await _pickImage(ImageSource.camera);
                  setModalState(() {}); // Cập nhật lại UI trong Modal
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _evidenceImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_evidenceImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.blue,
                            ),
                            Text(
                              "Chạm để chụp ảnh minh chứng",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Lưu Nhật Ký",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nhật ký: ${widget.productName}"),
        backgroundColor: Colors.green[700],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(
              child: Text(
                "Chưa có nhật ký nào.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                print("DATA LOG $index: $log");
                final date = DateTime.fromMillisecondsSinceEpoch(
                  (log['date'] ?? 0) * 1000,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ẢNH MINH CHỨNG
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            log['image'] ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // NỘI DUNG
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['type'] ?? "Hoạt động",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['desc'] ?? "Không có mô tả",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log['person'] ?? "Nông dân",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
