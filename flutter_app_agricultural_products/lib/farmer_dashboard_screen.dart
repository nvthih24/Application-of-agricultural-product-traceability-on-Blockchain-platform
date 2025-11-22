import 'dart:io'; // Để dùng kiểu 'File'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart'; // Để lấy kiểu file
import 'package:http_parser/http_parser.dart'; // Để set MediaType cho file

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  // Dùng IP 10.0.2.2 cho máy ảo Android
  final String _uploadUrl = 'http://10.0.2.2:5000/api/upload/image';
  final String _txUrl = 'http://10.0.2.2:5000/api/auth/transactions';

  final _productNameController = TextEditingController();
  final _productIdController = TextEditingController();
  final _farmNameController = TextEditingController();

  File? _plantingImage; // State để giữ file ảnh đã chọn
  bool _isLoading = false;

  // 1. HÀM CHỌN ẢNH (Dùng image_picker)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Bạn có thể dùng ImageSource.camera để chụp ảnh
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _plantingImage = File(image.path);
      });
    }
  }

  // 2. HÀM TẢI ẢNH LÊN (Giống handleImageUpload)
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final Uri uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Lấy kiểu file (VD: 'image/jpeg')
      final mimeType = lookupMimeType(imageFile.path);
      final mediaType = MediaType.parse(mimeType ?? 'image/jpeg');

      // Thêm file vào request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Tên field này phải giống backend ('image')
          imageFile.path,
          contentType: mediaType,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        return data['url']; // Trả về URL của ảnh
      } else {
        _showErrorDialog('Tải ảnh thất bại.');
        return null;
      }
    } catch (e) {
      _showErrorDialog('Lỗi tải ảnh: ${e.toString()}');
      return null;
    }
  }

  // 3. HÀM SUBMIT FORM (Giống handlePlantingSubmit)
  Future<void> _submitForm() async {
    if (_productNameController.text.isEmpty ||
        _productIdController.text.isEmpty ||
        _farmNameController.text.isEmpty ||
        _plantingImage == null) {
      _showErrorDialog('Vui lòng điền đủ thông tin và chọn ảnh.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // B1: Tải ảnh lên trước
      final String? imageUrl = await _uploadImage(_plantingImage!);
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return; // Dừng lại nếu tải ảnh lỗi
      }

      // B2: Lấy token đã lưu
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showErrorDialog('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // B3: Gửi thông tin giao dịch lên backend
      final Uri txUri = Uri.parse(_txUrl);
      final response = await http.post(
        txUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi JWT Token
        },
        body: jsonEncode({
          // Bạn cần 1 txHash "giả" vì txHash thật được tạo ở backend
          // Hoặc bạn sửa backend để không cần txHash từ client
          'txHash': 'pending_from_flutter',
          'productId': _productIdController.text,
          'userAddress': 'pending_from_flutter', // Backend nên lấy từ token
          'action': 'addProduct',
          'timestamp': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
          'plantingImageUrl': imageUrl,

          // Thêm các trường khác mà hàm addProduct cần
          'productName': _productNameController.text,
          'farmName': _farmNameController.text,
          'plantingDate': (DateTime.now().millisecondsSinceEpoch / 1000)
              .floor(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showErrorDialog('Thêm sản phẩm thành công!', isError: false);
        // Xóa form
        _productNameController.clear();
        _productIdController.clear();
        _farmNameController.clear();
        setState(() {
          _plantingImage = null;
        });
      } else {
        final error = jsonDecode(response.body);
        _showErrorDialog(error['error'] ?? 'Gửi thông tin thất bại');
      }
    } catch (e) {
      _showErrorDialog('Lỗi nghiêm trọng: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Nông Dân')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              ),
              TextField(
                controller: _productIdController,
                decoration: const InputDecoration(
                  labelText: 'Mã sản phẩm (ID)',
                ),
              ),
              TextField(
                controller: _farmNameController,
                decoration: const InputDecoration(labelText: 'Tên nông trại'),
              ),
              const SizedBox(height: 20),

              // Vùng hiển thị ảnh đã chọn
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _plantingImage != null
                    ? Image.file(_plantingImage!, fit: BoxFit.cover)
                    : const Center(child: Text('Chưa chọn ảnh')),
              ),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Chọn Ảnh Gieo Trồng'),
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Màu xanh
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 30,
                        ),
                      ),
                      child: const Text(
                        'Gửi Thông Tin Gieo Trồng',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
