import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_trace_screen.dart';

const Color kPrimaryColor = Color(0xFF00C853);

class FarmDetailScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;

  const FarmDetailScreen({super.key, required this.farmData});

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFarmProducts();
  }

  // Gọi API lấy sản phẩm của nông dân này
  Future<void> _fetchFarmProducts() async {
    // Lấy SĐT của nông trại từ dữ liệu truyền sang
    final String phone = widget.farmData['phone'] ?? "";

    if (phone.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Gọi vào API mới tạo
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products/by-farmer/$phone'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu nông trại
    String name = widget.farmData['fullName'] ?? "Nông trại";
    String address = widget.farmData['address'] ?? "Chưa cập nhật địa chỉ";
    String phone = widget.farmData['phone'] ?? "N/A";
    String email = widget.farmData['email'] ?? "N/A";
    String? avatar = widget.farmData['avatar'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. ẢNH BÌA
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: kPrimaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (avatar != null && avatar.isNotEmpty)
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset(
                            'assets/images/farm_1.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/farm_1.jpg',
                          fit: BoxFit.cover,
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. NỘI DUNG
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Giới thiệu",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$name là đơn vị tiên phong trong việc áp dụng quy trình VietGAP và công nghệ Blockchain.",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- DANH SÁCH SẢN PHẨM THẬT TỪ API ---
                  const Text(
                    "Sản phẩm tiêu biểu",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _products.isEmpty
                      ? const Text(
                          "Nông trại này chưa có sản phẩm nào trên Blockchain.",
                          style: TextStyle(color: Colors.grey),
                        )
                      : SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              return _buildProductItem(
                                context,
                                _products[index],
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 25),

                  // LIÊN HỆ
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Thông tin liên hệ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor,
                            backgroundImage:
                                (avatar != null && avatar.isNotEmpty)
                                ? NetworkImage(avatar)
                                : null,
                            child: (avatar == null || avatar.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(name),
                          subtitle: Text("$phone\n$email"),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Item Sản phẩm
  Widget _buildProductItem(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () {
        // Bấm vào thì sang trang Truy xuất nguồn gốc (Timeline) luôn cho xịn
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductTraceScreen(productId: product['id']),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                product['image'],
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 90,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['status'],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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
