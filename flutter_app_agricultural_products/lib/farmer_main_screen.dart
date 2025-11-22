import 'package:flutter/material.dart';
import 'add_crop_screen.dart'; // Form nhập liệu
import 'profile_screen.dart'; // Màn hình Profile
import 'harvest_product_screen.dart'; // Màn hình Thu hoạch
import 'care_diary_screen.dart'; // Màn hình Chăm sóc

// Màu xanh đậm chủ đạo
const Color kFarmerPrimaryColor = Color(0xFF2E7D32);

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});

  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const FarmerDashboardTab(), // Tab 0: Dashboard
    const Center(
      child: Text("Thông báo (Đang phát triển)"),
    ), // Tab 1: Thông báo
    const ProfileScreen(), // Tab 2: Tài khoản
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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

// ===============================================================
// PHẦN DASHBOARD CHÍNH (LOGIC FULL LUỒNG)
// ===============================================================
class FarmerDashboardTab extends StatefulWidget {
  const FarmerDashboardTab({super.key});

  @override
  State<FarmerDashboardTab> createState() => _FarmerDashboardTabState();
}

class _FarmerDashboardTabState extends State<FarmerDashboardTab> {
  // Biến tìm kiếm & lọc
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  String _selectedStatus = "Tất cả";

  // DỮ LIỆU GIẢ LẬP (3 TRẠNG THÁI ĐỂ TEST)
  final List<Map<String, dynamic>> myCrops = [
    {
      "id": "CAITHIA-001",
      "name": "Cải thìa hữu cơ",
      "status": "Chờ duyệt gieo trồng",
      "image": "assets/images/farm_1.jpg",
      "statusCode": 0, // KHÔNG CÓ NÚT
    },
    {
      "id": "DUAHAU-BATCH-123",
      "name": "Dưa hấu Long An",
      "status": "Đang trồng",
      "image": "assets/images/fruit.png",
      "statusCode": 1, // HIỆN NÚT CHĂM SÓC & THU HOẠCH
    },
    {
      "id": "LUA-BATCH-999",
      "name": "Lúa ST25",
      "status": "Đã thu hoạch",
      "image": "assets/images/lua.png",
      "statusCode": 2, // HIỆN NÚT XUẤT BÁN
    },
  ];

  List<Map<String, dynamic>> _foundProducts = [];

  @override
  void initState() {
    _foundProducts = List.from(myCrops);
    super.initState();
  }

  // --- LOGIC LỌC ---
  void _runFilter() {
    List<Map<String, dynamic>> results = [];
    if (_searchKeyword.isEmpty && _selectedStatus == "Tất cả") {
      results = myCrops;
    } else {
      results = myCrops.where((crop) {
        final matchName = crop["name"].toLowerCase().contains(
          _searchKeyword.toLowerCase(),
        );
        bool matchStatus = true;
        if (_selectedStatus != "Tất cả") {
          matchStatus = crop["status"].toString().contains(_selectedStatus);
        }
        return matchName && matchStatus;
      }).toList();
    }
    setState(() => _foundProducts = results);
  }

  // --- MODAL LỌC ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              child: Column(
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
                          "Chờ duyệt",
                          "Đang trồng",
                          "Đã thu hoạch",
                        ].map((status) {
                          bool isSelected = _selectedStatus == status;
                          return ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: kFarmerPrimaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (selected) {
                              setState(() => _selectedStatus = status);
                              setModalState(() {});
                            },
                          );
                        }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- HỘP THOẠI XUẤT BÁN ---
  void _showDistributeDialog(BuildContext context, String productId) {
    final retailerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xuất kho lô hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập ID người nhận (Thương lái):"),
            const SizedBox(height: 10),
            TextField(
              controller: retailerController,
              decoration: const InputDecoration(
                labelText: "Retailer ID / Ví",
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
                const SnackBar(content: Text("Đã gửi yêu cầu bàn giao!")),
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
                  hintText: "Tìm tên nông sản...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                onChanged: (value) {
                  _searchKeyword = value;
                  _runFilter();
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Dashboard Nông Dân",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    "3TML Farm",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchKeyword = "";
                  _searchController.clear();
                  _runFilter();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedStatus == "Tất cả"
                  ? Colors.white
                  : Colors.amberAccent,
            ),
            onPressed: _showFilterModal,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCropScreen()),
        ),
        backgroundColor: kFarmerPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm Mùa Vụ", style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Thống kê
            Row(
              children: [
                _buildStatCard("Tổng SP", "${myCrops.length}", Colors.blue),
                const SizedBox(width: 10),
                _buildStatCard("Đang trồng", "1", Colors.orange),
                const SizedBox(width: 10),
                _buildStatCard("Đã xong", "1", Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // Tiêu đề list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Danh sách sản phẩm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_selectedStatus != "Tất cả")
                  Text(
                    "Lọc: $_selectedStatus",
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // DANH SÁCH SẢN PHẨM (CHỈ CÓ 1 LISTVIEW DUY NHẤT)
            _foundProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text("Không tìm thấy kết quả"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _foundProducts.length,
                    itemBuilder: (context, index) {
                      return _buildCropCard(_foundProducts[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // WIDGET CARD SẢN PHẨM
  Widget _buildCropCard(Map<String, dynamic> crop) {
    int status = crop['statusCode'] ?? 0;
    String id = crop['id'];
    String name = crop['name'];
    String image = crop['image'];
    String statusText = crop['status'];

    Color statusColor = status == 0
        ? Colors.orange
        : (status == 1 ? Colors.blue : Colors.green);

    // Logic nút bấm
    bool isPlanting = (status == 1);
    bool isHarvested = (status == 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Thông tin
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Nút bấm
            if (isPlanting) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              CareDiaryScreen(productId: id, productName: name),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => HarvestProductScreen(
                            productId: id,
                            productName: name,
                          ),
                        ),
                      ),
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

            if (isHarvested) ...[
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

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 4)),
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
}
