import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../configs/constants.dart';

class HarvestProductScreen extends StatefulWidget {
  // Phải truyền ID và Tên sản phẩm từ Dashboard sang để biết đang thu hoạch cái gì
  final String productId;
  final String productName;

  const HarvestProductScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<HarvestProductScreen> createState() => _HarvestProductScreenState();
}

class _HarvestProductScreenState extends State<HarvestProductScreen> {
  // API
  final String _uploadUrl = '${Constants.baseUrl}/upload/image';
  final String _txUrl = '${Constants.baseUrl}/auth/transactions';

  // Controller
  final _quantityController = TextEditingController();
  final _qualityController =
      TextEditingController(); // VD: Loại 1, Đạt chuẩn...

  bool _isLoading = false;
  File? _selectedImage;

  // Hàm chọn ảnh (Tái sử dụng)
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Chọn ảnh từ source được truyền vào (Camera hoặc Gallery)
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Hàm hiển thị Menu chọn: Chụp ảnh hay Thư viện
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Chỉ chiếm chiều cao vừa đủ
          children: [
            const Text(
              "Chọn hình ảnh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút CHỤP ẢNH
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Đóng menu
                    _pickImage(ImageSource.camera); // Gọi Camera
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Chụp ảnh"),
                    ],
                  ),
                ),

                // Nút THƯ VIỆN
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Đóng menu
                    _pickImage(ImageSource.gallery); // Gọi Gallery
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Thư viện"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Hàm upload ảnh (Tái sử dụng)
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

  // HÀM SUBMIT THU HOẠCH
  Future<void> _submitHarvest() async {
    if (_quantityController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập sản lượng và ảnh thực tế!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload ảnh
      final String? imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) throw Exception("Lỗi upload ảnh");

      // 2. Lấy Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 3. Gửi API (Action: harvestProduct)
      final response = await http.post(
        Uri.parse(_txUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action':
              'harvestProduct', // <--- Action quan trọng trong Smart Contract
          'userAddress': 'pending',
          'txHash': 'pending',

          // Dữ liệu cần thiết cho hàm Thu Hoạch
          'productId': widget.productId, // Lấy từ màn hình trước
          'harvestDate': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          'quantity': _quantityController.text, // VD: 500
          'unit': 'kg', // Đơn vị (có thể làm dropdown chọn tấn/tạ/yến)
          'quality': _qualityController.text, // Chất lượng
          'harvestImageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thu hoạch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Quay về trang chủ (và nhớ reload lại list)
        Navigator.pop(context, true);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
        title: const Text("Xác Nhận Thu Hoạch"),
        backgroundColor: Colors.orange[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin sản phẩm (Read-only)
            Text(
              "Sản phẩm: ${widget.productName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Mã lô: ${widget.productId}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),

            // Form nhập liệu
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Sản lượng thu hoạch (Kg)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
                suffixText: "Kg",
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _qualityController,
              decoration: const InputDecoration(
                labelText: "Đánh giá chất lượng (VD: Loại 1)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Ảnh thực tế tại vườn:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt),
                            Text("Chụp ảnh lô hàng"),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                ),
                onPressed: _isLoading ? null : _submitHarvest,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Cập Nhật Lên Blockchain",
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
