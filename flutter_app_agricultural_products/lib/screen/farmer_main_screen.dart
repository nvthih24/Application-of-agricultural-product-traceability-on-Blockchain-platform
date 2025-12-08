import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'add_crop_screen.dart';
import 'profile_screen.dart';
import 'harvest_product_screen.dart';
import 'care_diary_screen.dart';
import 'notification_screen.dart';
import '../configs/constants.dart';

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
    const NotificationScreen(),
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
// DASHBOARD VỚI DỮ LIỆU THẬT & LOGIC CHUẨN
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
        Uri.parse('${Constants.baseUrl}/products/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> rawList = data['products'];
        List<Map<String, dynamic>> parsedList = rawList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          myCrops = parsedList;
          _foundProducts = List.from(myCrops);
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi server");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi kết nối: $e";
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

        // Logic lọc hiển thị (dựa trên status text)
        bool matchStatus = true;
        if (_selectedStatus != "Tất cả") {
          String statusText = crop["status"] ?? "";
          if (_selectedStatus == "Chờ duyệt")
            matchStatus = statusText.contains("Chờ duyệt");
          else if (_selectedStatus == "Đang trồng")
            matchStatus = statusText.contains("Đang");
          else if (_selectedStatus == "Đã thu hoạch")
            matchStatus = statusText.contains("Đã");
        }

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
                children: ["Tất cả", "Chờ duyệt", "Đang trồng", "Đã thu hoạch"]
                    .map((s) {
                      return ChoiceChip(
                        label: Text(s),
                        selected: _selectedStatus == s,
                        selectedColor: kFarmerPrimaryColor,
                        labelStyle: TextStyle(
                          color: _selectedStatus == s
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (v) {
                          setState(() => _selectedStatus = s);
                          setModalState(() {});
                        },
                      );
                    })
                    .toList(),
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

  // Hàm hiển thị Mã QR
  void _showQrDialog(BuildContext context, String data, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mã QR: $name", style: const TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // --- HÀM XUẤT BÁN (MỚI THÊM LẠI CHO ÔNG) ---
  void _showDistributeDialog(BuildContext context, String productId) {
    final retailerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xuất kho / Bàn giao"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập tên đơn vị vận chuyển để bàn giao:"),
            const SizedBox(height: 10),
            TextField(
              controller: retailerController,
              decoration: const InputDecoration(
                labelText: "Đơn vị vận chuyển",
                hintText: "VD: 3TML Logistics",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã sẵn sàng vận chuyển!")),
              );
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TÍNH TOÁN THỐNG KÊ (Dùng logic displayStatus mới để đếm cho chuẩn)
    // (Ở đây tôi đếm tạm theo logic cũ, ông có thể nâng cấp sau)
    int total = myCrops.length;
    int planting = myCrops
        .where(
          (c) =>
              c['plantingStatus'] == 1 &&
              (c['harvestDate'] == null || c['harvestDate'] == 0),
        )
        .length;
    int harvested = myCrops.where((c) => c['harvestStatus'] == 1).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kFarmerPrimaryColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCropScreen()),
          );
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // THỐNG KÊ
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

                    // TIÊU ĐỀ LIST
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

                    // DANH SÁCH
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
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(15),
                            itemCount: _foundProducts.length,
                            itemBuilder: (_, i) =>
                                _buildCropCard(_foundProducts[i]),
                          ),
                    const SizedBox(height: 80),
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
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CARD SẢN PHẨM (LOGIC MỚI NHẤT) ---
  Widget _buildCropCard(Map<String, dynamic> crop) {
    final String id = crop['id'] ?? '';
    final String name = crop['name'] ?? 'Không tên';
    final String imageUrl = crop['image'] ?? '';

    // 1. LẤY DỮ LIỆU TỪ API (Backend đã trả về đủ rồi)
    final int plantingStatus = crop['plantingStatus'] ?? 0;

    // Lưu ý: Backend trả về harvestDate là số (timestamp)
    final int harvestDate = (crop['harvestDate'] is int)
        ? crop['harvestDate']
        : 0;

    // Lưu ý: Backend trả về harvestStatus (0: Pending, 1: Approved, 2: Rejected)
    final int harvestStatus = crop['harvestStatus'] ?? 0;

    // 2. TÍNH TOÁN TRẠNG THÁI HIỂN THỊ (Logic 4 bước)
    int displayStatus = 0;

    if (plantingStatus == 0) {
      displayStatus = 0; // Chờ duyệt gieo trồng
    } else if (plantingStatus == 1) {
      // Đã duyệt gieo trồng -> Kiểm tra tiếp thu hoạch
      if (harvestDate > 0) {
        // Nông dân ĐÃ bấm nút thu hoạch
        if (harvestStatus == 0) {
          displayStatus = 2; // CHỜ DUYỆT THU HOẠCH (Cái ông đang cần)
        } else if (harvestStatus == 1) {
          displayStatus = 3; // ĐÃ DUYỆT THU HOẠCH (Xong)
        } else {
          displayStatus = -1; // Bị từ chối
        }
      } else {
        // Chưa bấm nút thu hoạch
        displayStatus = 1; // ĐANG TRỒNG
      }
    } else {
      displayStatus = -1; // Bị từ chối gieo trồng
    }

    // 3. CẤU HÌNH GIAO DIỆN (Màu sắc & Nút bấm)
    String statusText = "Không xác định";
    Color statusColor = Colors.grey;
    bool showHarvestBtn = false;
    bool showCareBtn = false;
    bool showDistributeBtn = false;
    bool showQrBtn = (plantingStatus == 1);

    if (displayStatus == 0) {
      statusText = "Chờ duyệt gieo trồng";
      statusColor = Colors.orange;
    } else if (displayStatus == 1) {
      statusText = "Đang canh tác";
      statusColor = Colors.blue;
      showCareBtn = true;
      showHarvestBtn = true;
    } else if (displayStatus == 2) {
      statusText = "Chờ duyệt thu hoạch"; // <--- NÓ SẼ HIỆN CÁI NÀY
      statusColor = Colors.purple;
      // Không hiện nút gì cả (Đúng logic)
    } else if (displayStatus == 3) {
      statusText = "Hoàn tất / Sẵn sàng bán";
      statusColor = Colors.green;
      showDistributeBtn = true;
    } else if (displayStatus == -1) {
      statusText = "Bị từ chối";
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- PHẦN 1: ẢNH & THÔNG TIN ---
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.local_florist),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (showQrBtn)
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_2,
                                color: Colors.black87,
                              ),
                              onPressed: () => _showQrDialog(context, id, name),
                            )
                          else if (statusText.contains("Chờ"))
                            Tooltip(
                              message: "Đang chờ...",
                              child: Icon(
                                Icons.hourglass_bottom,
                                size: 20,
                                color: statusColor,
                              ),
                            ),
                        ],
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

            // --- PHẦN 2: NÚT BẤM ---
            if (showCareBtn || showHarvestBtn) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  if (showCareBtn)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareDiaryScreen(
                              productId: id,
                              productName: name,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Chăm Sóc",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  if (showCareBtn && showHarvestBtn) const SizedBox(width: 10),
                  if (showHarvestBtn)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HarvestProductScreen(
                                productId: id,
                                productName: name,
                              ),
                            ),
                          );
                          _loadMyProducts(); // Reload khi quay về
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Thu Hoạch",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (showDistributeBtn) ...[
              const SizedBox(height: 12),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDistributeDialog(context, id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                  ),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: const Text(
                    "Xuất Bán / Bàn Giao",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
