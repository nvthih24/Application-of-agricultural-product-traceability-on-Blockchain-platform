import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../configs/constants.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final String _uploadUrl = '${Constants.baseUrl}/upload/image';
  final String _txUrl = '${Constants.baseUrl}/auth/transactions';

  final _productNameController = TextEditingController();
  // Thay ID nhập tay bằng Mã Lô Hàng tự sinh
  final _batchIdController = TextEditingController();
  // Thêm nguồn gốc giống
  final _seedSourceController = TextEditingController();
  File? _selectedImage;

  // Biến lưu tên nông trại tự động
  String _farmName = "Đang tải...";

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Tự động lấy thông tin khi vào màn hình
    _generateBatchId(); // Tự động tạo mã lô
  }

  // 1. Lấy tên nông trại từ bộ nhớ (Không cần nhập)
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Giả sử lúc login ông đã lưu 'farmName', nếu chưa thì lấy 'username'
      _farmName = prefs.getString('farmName') ?? "Nông trại 3TML (Mặc định)";
    });
  }

  // 2. Tự sinh mã lô hàng (VD: BATCH-1716...)
  void _generateBatchId() {
    int time = DateTime.now().millisecondsSinceEpoch;
    String random = Random().nextInt(999).toString().padLeft(3, '0');
    _batchIdController.text = "BATCH-$time-$random";
  }

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

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final Uri uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      final mimeType = lookupMimeType(imageFile.path);
      final mediaType = MediaType.parse(mimeType ?? 'image/jpeg');
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: mediaType,
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_productNameController.text.isEmpty ||
        _seedSourceController.text.isEmpty ||
        _selectedImage == null) {
      _showErrorDialog('Vui lòng nhập Tên, Nguồn gốc giống và Ảnh.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) {
        _showErrorDialog('Lỗi tải ảnh lên server.');
        setState(() => _isLoading = false);
        return;
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
          'action': 'addProduct',
          // 'txHash' và 'userAddress' không cần gửi nữa → backend tự xử lý
          'productId': _batchIdController.text,
          'productName': _productNameController.text,
          'farmName': _farmName,
          'seedSource':
              _seedSourceController.text, // tên field đúng với contract
          'plantingDate': (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
          'plantingImageUrl': imageUrl,
          "creatorPhone": prefs.getString('phone'), // lấy từ SharedPreferences
          "creatorName": prefs.getString('name') ?? "Nông dân",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showErrorDialog('Khởi tạo mùa vụ thành công!', isError: false);
        Navigator.pop(context); // Quay về Dashboard sau khi xong
      } else {
        _showErrorDialog('Lỗi server: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gieo Trồng Mới'),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị thông tin Nông trại (Read-only)
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nông trại:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _farmName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _batchIdController,
              readOnly: true, // Không cho sửa mã
              decoration: const InputDecoration(
                labelText: 'Mã Lô Hàng (Tự động)',
                filled: true,
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Tên sản phẩm (VD: Dưa lưới)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco),
              ),
            ),
            const SizedBox(height: 15),

            // TRƯỜNG MỚI QUAN TRỌNG
            TextField(
              controller: _seedSourceController,
              decoration: const InputDecoration(
                labelText: 'Nguồn gốc hạt giống/Vật tư',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Hình ảnh thực tế:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text(
                            "Chạm để chụp/chọn ảnh",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác Nhận Gieo Trồng Lên Blockchain',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
