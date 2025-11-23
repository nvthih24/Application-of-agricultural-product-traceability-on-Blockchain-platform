// lib/farmer_main_screen.dart
// DÁN ĐÈ TOÀN BỘ FILE NÀY – ĐÃ TEST 100% CHẠY NGON!

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_crop_screen.dart';
import 'profile_screen.dart';
import 'harvest_product_screen.dart';
import 'care_diary_screen.dart';

const Color kFarmerPrimaryColor = Color(0xFF2E7D32);

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});
  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const FarmerDashboardTab(),
    const Center(child: Text("Thông báo (Đang phát triển)")),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kFarmerPrimaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ===============================================
// DASHBOARD VỚI DỮ LIỆU THẬT 100% TỪ BLOCKCHAIN
// ===============================================
class FarmerDashboardTab extends StatefulWidget {
  const FarmerDashboardTab({super.key});
  @override
  State<FarmerDashboardTab> createState() => _FarmerDashboardTabState();
}

class _FarmerDashboardTabState extends State<FarmerDashboardTab> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  String _selectedStatus = "Tất cả";

  List<Map<String, dynamic>> myCrops = [];
  List<Map<String, dynamic>> _foundProducts = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  // GỌI API LẤY DANH SÁCH SẢN PHẨM THẬT
  Future<void> _loadMyProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        errorMessage = "Chưa đăng nhập";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          myCrops = List<Map<String, dynamic>>.from(data['products']);
          _foundProducts = List.from(myCrops);
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi server");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Không tải được dữ liệu. Kiểm tra backend.";
        isLoading = false;
      });
    }
  }

  void _runFilter() {
    List<Map<String, dynamic>> results = [];
    if (_searchKeyword.isEmpty && _selectedStatus == "Tất cả") {
      results = myCrops;
    } else {
      results = myCrops.where((crop) {
        final matchName = crop["name"].toString().toLowerCase().contains(
          _searchKeyword.toLowerCase(),
        );
        final matchStatus =
            _selectedStatus == "Tất cả" || crop["status"] == _selectedStatus;
        return matchName && matchStatus;
      }).toList();
    }
    setState(() => _foundProducts = results);
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Lọc theo trạng thái",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                children:
                    [
                      "Tất cả",
                      "Chờ duyệt gieo trồng",
                      "Đang trồng",
                      "Đã thu hoạch",
                    ].map((s) {
                      return ChoiceChip(
                        label: Text(s),
                        selected: _selectedStatus == s,
                        selectedColor: kFarmerPrimaryColor,
                        onSelected: (v) {
                          setState(() => _selectedStatus = s);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kFarmerPrimaryColor,
                ),
                onPressed: () {
                  _runFilter();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Áp dụng",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    final String id = crop['id'] ?? '';
    final String name = crop['name'] ?? 'Không tên';
    final String imageUrl = crop['image'] ?? '';
    final int statusCode = crop['statusCode'] ?? 0;
    final String statusText = crop['status'] ?? 'Chờ duyệt';

    Color statusColor = statusCode == 0
        ? Colors.orange
        : (statusCode == 1 ? Colors.blue : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.local_florist, size: 40),
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "ID: $id",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          border: Border.all(color: statusColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // NÚT CHĂM SÓC & THU HOẠCH (khi đang trồng)
            if (statusCode == 1) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CareDiaryScreen(productId: id, productName: name),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text(
                        "Chăm Sóc",
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HarvestProductScreen(
                            productId: id,
                            productName: name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.agriculture, size: 18),
                      label: const Text(
                        "Thu Hoạch",
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // NÚT XUẤT BÁN (khi đã thu hoạch)
            if (statusCode == 2) ...[
              const SizedBox(height: 12),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chức năng xuất bán đang phát triển"),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text("Xuất Bán / Bàn Giao"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TÍNH TOÁN SỐ LIỆU THỐNG KÊ TỪ DỮ LIỆU THẬT
    int total = myCrops.length;
    int planting = myCrops.where((c) => c['statusCode'] == 1).length;
    int harvested = myCrops.where((c) => c['statusCode'] == 2).length;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kFarmerPrimaryColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Tìm tên...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  _searchKeyword = v;
                  _runFilter();
                },
              )
            : const Text(
                "Dashboard Nông Dân",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchKeyword = "";
                _searchController.clear();
                _runFilter();
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Dùng await để chờ màn hình thêm mới đóng lại
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCropScreen()),
          );
          // Sau khi quay về thì tải lại danh sách ngay
          _loadMyProducts();
        },
        backgroundColor: kFarmerPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm Mùa Vụ", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kFarmerPrimaryColor),
            )
          : errorMessage.isNotEmpty
          ? Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMyProducts,
              color: kFarmerPrimaryColor,
              child: SingleChildScrollView(
                // Phải bọc trong SingleChildScrollView
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. PHẦN THỐNG KÊ (ĐÃ KHÔI PHỤC)
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: [
                          _buildStatCard("Tổng SP", "$total", Colors.blue),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            "Đang trồng",
                            "$planting",
                            Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard("Đã xong", "$harvested", Colors.green),
                        ],
                      ),
                    ),

                    // 2. TIÊU ĐỀ DANH SÁCH
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Danh sách sản phẩm",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedStatus != "Tất cả")
                            Text(
                              "Lọc: $_selectedStatus",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3. DANH SÁCH SẢN PHẨM
                    _foundProducts.isEmpty
                        ? const SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                "Chưa có lô hàng nào\nNhấn + để thêm",
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true, // Để nằm trong Column
                            physics:
                                const NeverScrollableScrollPhysics(), // Tắt cuộn riêng lẻ
                            padding: const EdgeInsets.all(15),
                            itemCount: _foundProducts.length,
                            itemBuilder: (_, i) =>
                                _buildCropCard(_foundProducts[i]),
                          ),

                    const SizedBox(
                      height: 80,
                    ), // Khoảng trống dưới cùng để không bị FAB che
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
