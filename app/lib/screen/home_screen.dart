import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Nhớ import cái này
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'qr_scanner_screen.dart';
import 'farm_detail_screen.dart';
import 'profile_screen.dart';
import 'product_trace_screen.dart';
import '../configs/constants.dart';

const Color kPrimaryColor = Color(0xFF00C853);
const Color kBackgroundColor = Color(0xFFF5F5F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    const Center(child: Text("Đang nâng cấp (Saved)")),
    const Center(child: Text("Đang nâng cấp (Orders)")),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ====================
// PHẦN NỘI DUNG TRANG CHỦ (NÂNG CẤP)
// ====================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> _allFarms = []; // Danh sách gốc
  List<dynamic> _filteredFarms = []; // Danh sách hiển thị
  bool _isLoading = true;
  List<dynamic> _newArrivals = [];

  String _searchKeyword = "";
  String _selectedCategory = "Tất cả"; // Filter mặc định

  // Danh sách Banner quảng cáo
  final List<String> imgList = [
    'assets/images/banner-2.jpg', // Ảnh 1 (Nhớ đảm bảo file tồn tại)
    'assets/images/farm_1.jpg', // Ảnh 2
    'assets/images/fruit.png', // Ảnh 3
  ];

  // Hàm lọc danh sách dựa trên Tên sản phẩm
  List<dynamic> _getFilteredProducts() {
    if (_selectedCategory == "Tất cả") {
      return _newArrivals;
    }

    return _newArrivals.where((product) {
      // Lấy tên sản phẩm, chuyển về chữ thường để so sánh
      String name = (product['name'] ?? "").toString().toLowerCase();

      if (_selectedCategory == "Rau củ") {
        return name.contains("rau") ||
            name.contains("cải") ||
            name.contains("xà lách") ||
            name.contains("khoai") ||
            name.contains("cà") ||
            name.contains("bí");
      } else if (_selectedCategory == "Trái cây") {
        return name.contains("dưa") ||
            name.contains("cam") ||
            name.contains("táo") ||
            name.contains("xoài") ||
            name.contains("ổi") ||
            name.contains("mận") ||
            name.contains("chuối");
      } else if (_selectedCategory == "Gạo") {
        return name.contains("gạo") ||
            name.contains("lúa") ||
            name.contains("nếp");
      } else if (_selectedCategory == "Hạt") {
        return name.contains("hạt") ||
            name.contains("đậu") ||
            name.contains("điều") ||
            name.contains("tiêu");
      }
      return false; // Không khớp cái nào
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData(); // Gọi cả 2 API
  }

  Future<void> _fetchData() async {
    try {
      // 1. Lấy danh sách Nông trại
      final resFarms = await http.get(
        Uri.parse('${Constants.baseUrl}/auth/farmers'),
      );
      if (resFarms.statusCode == 200) {
        final data = jsonDecode(resFarms.body);
        setState(() {
          _allFarms = data['data'];
          _filteredFarms = _allFarms;
        });
      }

      // 2. Lấy danh sách Sản phẩm mới lên kệ
      final resProducts = await http.get(
        Uri.parse('${Constants.baseUrl}/products/on-shelf'),
      );
      if (resProducts.statusCode == 200) {
        setState(() {
          _newArrivals = jsonDecode(resProducts.body)['data'];
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Lỗi: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logic Lọc (Kết hợp Tìm kiếm & Danh mục)
  void _runFilter() {
    List<dynamic> results = _allFarms;

    // 1. Lọc theo Search Text
    if (_searchKeyword.isNotEmpty) {
      results = results.where((farm) {
        final name = (farm['fullName'] ?? "").toLowerCase();
        final address = (farm['address'] ?? "").toLowerCase();
        return name.contains(_searchKeyword.toLowerCase()) ||
            address.contains(_searchKeyword.toLowerCase());
      }).toList();
    }

    // 2. Lọc theo Danh mục (Giả lập logic)
    // Vì DB chưa có field category, nên ta giả bộ lọc theo tên
    if (_selectedCategory != "Tất cả") {
      // Ví dụ: Nếu chọn "Rau củ", lọc những ông có tên chứa chữ "Rau" hoặc "Farm"
      // (Đây là logic tạm để demo hiệu ứng lọc)
      results = results
          .where((farm) => farm['fullName'].toString().contains("Farm"))
          .toList();
    }

    setState(() {
      _filteredFarms = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // APP BAR
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leadingWidth: 60.5,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage("assets/images/3TMLNS.ico"),
            backgroundColor: Colors.white,
          ),
        ),
        title: const Text(
          "3TML FARM",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER CHẠY TỰ ĐỘNG (CAROUSEL)
            Stack(
              children: [
                // Nền xanh cong cong ở dưới cùng
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Stack(
                    alignment: Alignment.bottomLeft, // Căn chữ ở góc dưới trái
                    children: [
                      // LỚP 1: ẢNH CHẠY (CAROUSEL)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 160.0,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          enlargeCenterPage: true, // Phóng to ảnh giữa
                          viewportFraction: 0.9,
                        ),
                        items: imgList.map((item) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: AssetImage(item),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                // Lớp phủ đen mờ (Gradient) đi theo ảnh để ảnh nào cũng tối phần dưới cho dễ đọc chữ
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),

                      // LỚP 2: CHỮ ĐỨNG YÊN (Nằm đè lên trên Carousel)
                      // Vì Carousel có viewportFraction=0.9 và margin, nên ta căn chỉnh Positioned cho khớp
                      const Positioned(
                        bottom: 20,
                        left: 35, // Căn lề trái cho khớp với mép ảnh giữa
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nông sản sạch",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 5, color: Colors.black),
                                ],
                              ),
                            ),
                            Text(
                              "Cho mọi nhà",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                shadows: [
                                  Shadow(blurRadius: 5, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. THANH TÌM KIẾM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (value) {
                  _searchKeyword = value;
                  _runFilter();
                },
                decoration: InputDecoration(
                  hintText: "Tìm nông trại, địa chỉ...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. BỘ LỌC DANH MỤC (CATEGORY CHIPS)
            _buildSectionTitle("Danh mục", () {}),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip("Tất cả", Icons.apps),
                  _buildCategoryChip("Rau củ", Icons.eco),
                  _buildCategoryChip("Trái cây", Icons.circle),
                  _buildCategoryChip("Gạo", Icons.grass),
                  _buildCategoryChip("Hạt", Icons.lens),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_newArrivals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: const Text(
                  "🔥 Mới lên kệ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _getFilteredProducts().length,
                  itemBuilder: (context, index) =>
                      _buildNewProductCard(_getFilteredProducts()[index]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. DANH SÁCH NÔNG TRẠI (REAL DATA)
            _buildSectionTitle("🔥 Nông trại tiêu biểu", () {}),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : _filteredFarms.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text("Không tìm thấy nông trại nào.")),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredFarms.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      return _buildFarmCard(context, _filteredFarms[index]);
                    },
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Widget Tiêu đề
  Widget _buildSectionTitle(String title, VoidCallback onPress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          GestureDetector(
            onTap: onPress,
            child: const Text("Xem thêm", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Widget Category Chip (Đã có logic đổi màu)
  Widget _buildCategoryChip(String label, IconData icon) {
    bool isSelected = _selectedCategory == label; // Kiểm tra có đang chọn không

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label; // Cập nhật danh mục
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          // Nếu chọn thì màu Xanh, không thì màu Trắng xám
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Farm Card (Giữ nguyên logic hiển thị ảnh thật)
  Widget _buildFarmCard(BuildContext context, dynamic farm) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmDetailScreen(farmData: farm),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag:
                  "farm_img_${farm['_id'] ?? farm['phone']}", // Tag phải khớp với trang chi tiết
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child:
                    (farm['avatar'] != null &&
                        farm['avatar'].toString().isNotEmpty)
                    ? Image.network(
                        farm['avatar'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/farm_1.jpg',
                          fit: BoxFit.cover,
                          height: 150,
                        ),
                      )
                    : Image.asset(
                        'assets/images/farm_1.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (farm['companyName'] != null &&
                                farm['companyName'].toString().isNotEmpty)
                            ? farm['companyName']
                            : (farm['fullName'] ?? "Nông trại chưa đặt tên"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          farm['address'] ?? "Chưa cập nhật",
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Card Sản Phẩm Mới (Ngang)
  Widget _buildNewProductCard(dynamic item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductTraceScreen(productId: item['id']),
        ),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm (Có Hero Animation cho xịn)
            Hero(
              tag: "product_img_${item['id']}", // Tag duy nhất
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  item['image'],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 100, color: Colors.grey[200]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['farm'] ?? "",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item['price']} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
