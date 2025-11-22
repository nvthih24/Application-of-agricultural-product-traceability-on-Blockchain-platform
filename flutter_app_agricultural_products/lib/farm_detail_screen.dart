import 'package:flutter/material.dart';
import 'product_detail_screen.dart'; // Để bấm vào dưa hấu thì sang trang chi tiết

const Color kPrimaryColor = Color(0xFF00C853);

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Cho phép ảnh tràn lên thanh trạng thái
      body: CustomScrollView(
        slivers: [
          // 1. Phần ảnh bìa nông trại (Hiệu ứng co giãn khi cuộn)
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: kPrimaryColor,
            // Thêm dòng này để nút Back (mũi tên quay lại) cũng thành màu trắng
            iconTheme: const IconThemeData(color: Colors.white),

            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true, // Căn giữa tiêu đề (nhìn sẽ cân đối hơn)
              title: const Text(
                "3TML Farm",
                style: TextStyle(
                  color: Colors.white, // 1. Đổi màu trắng
                  fontWeight: FontWeight.bold, // 2. Chữ đậm cho khỏe khoắn
                  fontFamily:
                      'Roboto', // (Tùy chọn) Font mặc định đã khá ổn, hoặc đổi font khác
                  fontSize: 18, // Kích thước chữ vừa phải khi co lại
                  // 3. Đổ bóng nhẹ để chữ nổi bật trên nền ảnh
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54, // Màu bóng đen mờ
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/farm_1.jpg', fit: BoxFit.cover),
                  // (Tùy chọn) Lớp phủ đen mờ nhẹ giúp chữ dễ đọc hơn nữa
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(
                            0.3,
                          ), // Đen mờ ở dưới đáy ảnh
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Nội dung chi tiết
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Địa chỉ
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 18),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "36363 SW 217th Ave, Homestead, FL 33034, United States",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tiêu đề Description
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "3TML Farm là ứng dụng tiên phong sử dụng công nghệ Blockchain trong nông nghiệp. Sứ mệnh của chúng tôi là mang lại sự minh bạch, hiệu quả và niềm tin cho chuỗi cung ứng nông sản.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Danh sách sản phẩm của nông trại (Ngang)
                  const Text(
                    "Agricultural products",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 140, // Chiều cao khu vực lướt ngang
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildProductItem(
                          context,
                          "Watermelon",
                          "assets/images/fruit.png",
                        ), // Dưa hấu
                        _buildProductItem(
                          context,
                          "Grapefruit",
                          "assets/images/fruit.png",
                        ), // Bưởi (tạm dùng chung ảnh)
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Phần liên hệ (Contact)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Contact Farm Owner",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text("3TML Farm Owner"),
                          subtitle: Text("0986542518\n3tmlfarm01@gmail.com"),
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

  // Widget con: Item sản phẩm (Dưa hấu, Bưởi...)
  Widget _buildProductItem(
    BuildContext context,
    String name,
    String imagePath,
  ) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang màn hình chi tiết sản phẩm
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductDetailScreen()),
        );
      },
      child: Container(
        width: 120,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 60,
              fit: BoxFit.contain,
            ), // Ảnh sản phẩm
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
