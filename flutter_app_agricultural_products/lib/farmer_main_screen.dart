import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_crop_screen.dart';
import 'profile_screen.dart';
import 'harvest_product_screen.dart';
import 'care_diary_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                      "Chờ duyệt thu hoạch",
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

    // Lấy dữ liệu từ API
    final int statusCode =
        crop['statusCode'] ??
        0; // 0: Pending, 1: Approved/Planting, 2: Harvested
    final int plantingStatus = crop['plantingStatus'] ?? 0;
    final int harvestStatus = crop['harvestStatus'] ?? 0;

    // Lấy harvestDate (Backend cần trả về trường này, nếu là số 0 nghĩa là chưa thu hoạch)
    // Lưu ý: check kỹ xem backend trả về 'harvestDate' hay 'dates'['harvest']
    // Ở đây giả định crop là item trong list myCrops đã được flatten
    final int harvestDate = crop['harvestDate'] is int
        ? crop['harvestDate']
        : 0;

    // --- LOGIC HIỂN THỊ TRẠNG THÁI (QUAN TRỌNG) ---
    String statusText = "Không xác định";
    Color statusColor = Colors.grey;

    bool showHarvestBtn = false;
    bool showQrBtn = false;
    bool showCareBtn = false;
    bool showDistributeBtn = false;

    // 1. CHỜ DUYỆT GIEO TRỒNG
    if (plantingStatus == 0) {
      statusText = "Chờ duyệt gieo trồng";
      statusColor = Colors.orange;
    }
    // 2. ĐÃ DUYỆT GIEO TRỒNG (PlantingStatus == 1)
    else if (plantingStatus == 1) {
      // Kiểm tra xem đã gửi yêu cầu thu hoạch chưa?
      if (harvestDate > 0) {
        // Đã gửi yêu cầu thu hoạch
        if (harvestStatus == 0) {
          // Case: Đã gửi nhưng CHƯA được duyệt
          statusText = "Chờ duyệt thu hoạch";
          statusColor = Colors.purple; // Màu tím để phân biệt
          // Không hiện nút gì cả (vì đang chờ)
        } else if (harvestStatus == 1) {
          // Case: Đã được duyệt
          statusText = "Đã thu hoạch";
          statusColor = Colors.green;
          showQrBtn = true; // Hiện nút lấy mã QR
          showDistributeBtn = true; // Hiện nút xuất bán
        } else {
          statusText = "Thu hoạch bị từ chối";
          statusColor = Colors.red;
        }
      } else {
        // Chưa gửi yêu cầu thu hoạch -> Đang canh tác
        statusText = "Đang canh tác";
        statusColor = Colors.blue;
        showHarvestBtn = true; // Hiện nút thu hoạch
        showCareBtn = true; // Hiện nút chăm sóc
      }
    }

    // Logic QR Code (chỉ hiện khi đã được duyệt gieo trồng)
    // Tuy nhiên nếu đang chờ duyệt thu hoạch thì cũng có thể ẩn đi nếu muốn
    bool isApproved = (plantingStatus == 1);

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

                          // Logic hiển thị icon QR hoặc Đồng hồ cát
                          if (showQrBtn) // Chỉ hiện khi hoàn tất thu hoạch (hoặc tùy logic bạn muốn)
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_2,
                                color: Colors.black87,
                              ),
                              onPressed: () => _showQrDialog(context, id, name),
                            )
                          else if (statusText.contains(
                            "Chờ",
                          )) // Nếu đang chờ duyệt (gieo hoặc thu)
                            Tooltip(
                              message: "Đang chờ duyệt...",
                              child: Icon(
                                Icons.hourglass_bottom,
                                size: 20,
                                color: statusColor,
                              ),
                            )
                          else if (isApproved) // Đã duyệt gieo trồng nhưng chưa thu hoạch -> Vẫn cho xem QR truy xuất quá trình
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_2,
                                color: Colors.grey,
                              ),
                              onPressed: () => _showQrDialog(context, id, name),
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

            // --- KHU VỰC NÚT BẤM ---
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
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text(
                          "Chăm Sóc",
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (showCareBtn && showHarvestBtn) const SizedBox(width: 10),
                  if (showHarvestBtn)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Dùng await để khi quay lại thì reload
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HarvestProductScreen(
                                productId: id,
                                productName: name,
                              ),
                            ),
                          );
                          _loadMyProducts(); // Reload lại list sau khi submit
                        },
                        icon: const Icon(Icons.agriculture, size: 18),
                        label: const Text(
                          "Thu Hoạch",
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                  icon: const Icon(Icons.local_shipping),
                  label: const Text("Xuất Bán / Bàn Giao"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị Popup Xuất Bán / Bàn Giao
  void _showDistributeDialog(BuildContext context, String productId) {
    final retailerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xuất kho / Bàn giao"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nhập tên hoặc mã của Nhà vận chuyển / Thương lái để bàn giao lô hàng này:",
            ),
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
              // Ở đây có thể gọi API cập nhật trạng thái nếu cần
              // Nhưng theo quy trình hiện tại, chỉ cần Nông dân "gật đầu" (Off-chain) là Tài xế quét được.
              // Hoặc lưu 'transporterName' vào DB tại đây để chỉ định đích danh tài xế.

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Đã gửi yêu cầu bàn giao! Đợi tài xế đến nhận.",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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

  // Hàm hiển thị Mã QR phóng to để in hoặc quét
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
              data: data, // Dữ liệu chính là ID lô hàng (VD: BATCH-1732...)
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
          ElevatedButton.icon(
            onPressed: () {
              // Tính năng nâng cao: Kết nối máy in hoặc Lưu ảnh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã gửi lệnh đến máy in! (Giả lập)"),
                ),
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text("In Tem", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kFarmerPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
