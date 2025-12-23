import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../configs/constants.dart';
import 'farm_detail_screen.dart'; // Nhớ import trang chi tiết của ông

class AllFarmsScreen extends StatefulWidget {
  const AllFarmsScreen({super.key});

  @override
  State<AllFarmsScreen> createState() => _AllFarmsScreenState();
}

class _AllFarmsScreenState extends State<AllFarmsScreen> {
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _farms = [];
  bool _isLoading = false;
  bool _hasMore = true; // Còn dữ liệu để tải không?
  int _currentPage = 1;
  final int _limit = 10; // Số lượng tải mỗi lần

  @override
  void initState() {
    super.initState();
    _fetchFarms(); // Tải lần đầu

    // Lắng nghe sự kiện cuộn
    _scrollController.addListener(() {
      // Nếu cuộn xuống gần đáy (còn 200px) và không đang tải và còn dữ liệu
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchFarms(); // Tải trang tiếp theo
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarms() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Uri url = Uri.parse(
        '${Constants.baseUrl}/auth/farmers?page=$_currentPage&limit=$_limit',
      );

      print("Đang tải trang: $_currentPage"); // Debug xem nó chạy không

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List newFarms = data['data'];

        setState(() {
          _currentPage++; // Tăng số trang cho lần sau
          _farms.addAll(newFarms); // Cộng dồn vào danh sách cũ

          // Nếu số lượng trả về ít hơn limit -> Hết dữ liệu rồi
          if (newFarms.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      print("Lỗi tải nông trại: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả nông trại"),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
      ),
      body: _farms.isEmpty && _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            )
          : ListView.builder(
              controller: _scrollController, // Gắn controller vào đây
              padding: const EdgeInsets.all(16),
              itemCount: _farms.length + 1, // +1 cho cái loading ở đáy
              itemBuilder: (context, index) {
                // Nếu là item cuối cùng
                if (index == _farms.length) {
                  return _buildBottomLoader();
                }

                // Render item nông trại
                final farm = _farms[index];
                return _buildFarmCard(farm);
              },
            ),
    );
  }

  // Widget Loading ở đáy danh sách
  Widget _buildBottomLoader() {
    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "Đã hiển thị hết danh sách",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            ),
          )
        : const SizedBox.shrink(); // Ẩn đi nếu không tải
  }

  // Card hiển thị nông trại (Copy từ Home sang cho đồng bộ hoặc custom tùy ý)
  Widget _buildFarmCard(dynamic farm) {
    String tag = "all_farms_${farm['_id'] ?? farm['phone']}";
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmDetailScreen(farmData: farm, heroTag: tag),
            ),
          );
        },
        leading: Hero(
          tag: tag,
          child: CircleAvatar(
            radius: 30,
            backgroundImage:
                (farm['avatar'] != null && farm['avatar'].toString().isNotEmpty)
                ? NetworkImage(farm['avatar'])
                : const AssetImage('assets/images/farm_1.jpg') as ImageProvider,
          ),
        ),
        title: Text(
          farm['companyName'] ?? farm['fullName'] ?? "Nông trại",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(farm['phone'] ?? "Chưa cập nhật"),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    farm['address'] ?? "Chưa cập nhật",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
