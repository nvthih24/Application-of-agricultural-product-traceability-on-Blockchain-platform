import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // API Config
  final String _uploadUrl = '${Constants.baseUrl}/upload/image';
  final String _txUrl = '${Constants.baseUrl}/auth/transactions';

  // Các loại hoạt động chăm sóc thường gặp
  final List<String> _activities = [
    "Tưới nước",
    "Bón phân",
    "Phun thuốc",
    "Làm cỏ",
    "Kiểm tra sâu bệnh",
  ];
  String _selectedActivity = "Tưới nước"; // Mặc định chọn cái đầu

  final _descriptionController = TextEditingController();
  File? _careImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _careImage = File(image.path));
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      final mimeType = lookupMimeType(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitDiary() async {
    if (_descriptionController.text.isEmpty && _careImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả hoặc chụp ảnh minh chứng!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_careImage != null) {
        imageUrl = await _uploadImage(_careImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi upload ảnh'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(_txUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // 1. Sửa action cho đúng
          "action": "logCare",

          // 2. ĐÚNG TÊN FIELD TRONG CONTRACT
          "productId": widget.productId,
          "careType": _selectedActivity,
          "description": _descriptionController.text.trim(),
          "careDate": (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          "careImageUrl": imageUrl ?? "", // nếu không có ảnh thì để rỗng
          "creatorPhone": prefs.getString('phone'), // lấy từ SharedPreferences
          "creatorName": prefs.getString('name') ?? "Nông dân",
        }),
      );

      // 3. Xử lý response chuẩn
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ghi nhật ký thành công! Tx: ${result['txHash']?.substring(0, 10)}...",
            ),
            backgroundColor: Colors.green,
            action: result['txHash'] != null
                ? SnackBarAction(
                    label: "Xem",
                    textColor: Colors.white,
                    onPressed: () {
                      // Mở explorer (ví dụ ZeroScan)
                      launchUrl(
                        Uri.parse(
                          "https://zeroscan.org/tx/${result['txHash']}",
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
        Navigator.pop(context); // Quay lại dashboard
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Lỗi server';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $error"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nhật Ký Chăm Sóc"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.spa, color: Colors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Đang chăm sóc: ${widget.productName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Chọn hoạt động:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _activities.map((activity) {
                final isSelected = _selectedActivity == activity;
                return ChoiceChip(
                  label: Text(activity),
                  selected: isSelected,
                  selectedColor: Colors.teal[200],
                  onSelected: (selected) {
                    setState(() => _selectedActivity = activity);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Chi tiết (VD: Tên phân bón, liều lượng...)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Ảnh minh chứng (Vỏ thuốc/Phân bón):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: _careImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_careImage!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey),
                            Text("Chụp ảnh"),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _isLoading ? null : _submitDiary,
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Lưu Nhật Ký",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
