import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'scan_history';

  // 1. Lấy danh sách lịch sử
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    // Convert từ chuỗi JSON sang List
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // 2. Thêm một sản phẩm vào lịch sử
  static Future<void> addToHistory(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentList = await getHistory();

    // Kiểm tra trùng lặp (nếu muốn): Xóa cái cũ đi để đưa cái mới lên đầu
    currentList.removeWhere((item) => item['id'] == product['id']);

    // Thêm thời gian quét hiện tại
    product['scan_time'] = DateTime.now().toString();

    // Đưa lên đầu danh sách
    currentList.insert(0, product);

    // Lưu lại vào máy
    await prefs.setString(_key, jsonEncode(currentList));
  }

  // 3. Xóa sạch lịch sử
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
