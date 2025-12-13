import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configs/constants.dart';

// Hàm gửi Token lên Server
Future<void> saveDeviceToken(String userId, String token) async {
  final String url = '${Constants.baseUrl}/auth/save-device-token';

  print("🚀 [Flutter] Đang gửi Token lên: $url");
  print("👤 UserID: $userId");

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "token": token}),
    );

    if (response.statusCode == 200) {
      print("✅ [Flutter] Server báo đã lưu thành công!");
    } else {
      print("❌ [Flutter] Lỗi server: ${response.body}");
    }
  } catch (e) {
    print("❌ [Flutter] Lỗi kết nối: $e");
  }
}

// Thêm tham số secretKey vào hàm
Future<http.Response> register(
  String fullName,
  String email,
  String password,
  String role,
  String companyName,
  String secretKey, // <--- THÊM CÁI NÀY
) async {
  final url = Uri.parse('${Constants.baseUrl}/auth/register');

  return await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      'companyName': companyName,
      'secretKey': secretKey, // <--- GỬI LÊN SERVER
    }),
  );
}
