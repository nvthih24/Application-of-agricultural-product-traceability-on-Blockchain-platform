import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Biến kiểm soát xem đã phát hiện mã hay chưa (để tránh quét liên tục)
  bool _isScanCompleted = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanCompleted) return; // Nếu đã xử lý thì bỏ qua

    final String? productId = capture.barcodes.first.rawValue;

    if (productId == null || productId.isEmpty) {
      // Hiển thị lỗi nếu mã QR rỗng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đọc mã QR!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanCompleted = true; // Đánh dấu là đã xử lý
    });

    // --- BƯỚC TIẾP THEO ---
    // Đây là nơi bạn sẽ điều hướng đến Màn hình Chi tiết Sản phẩm.
    // Tạm thời chúng ta sẽ in ra console và hiển thị thông báo.

    print('Đã quét được Product ID: $productId');

    // Hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tìm thấy sản phẩm: $productId'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Thay thế bằng lệnh điều hướng:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (ctx) => ProductDetailScreen(productId: productId),
    //   ),
    // ).then((_) {
    //   // Khi người dùng quay lại từ màn hình chi tiết, cho phép quét tiếp
    //   setState(() {
    //     _isScanCompleted = false;
    //   });
    // });

    // (Tạm thời) Reset lại sau 3 giây để bạn có thể quét tiếp
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isScanCompleted = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Mã QR Sản Phẩm'),
        // Thêm nút bật/tắt đèn flash
        actions: [
          IconButton(
            onPressed: () {
              // Lấy controller của MobileScanner và gọi toggleTorch()
              // Cần 1 cách quản lý state phức tạp hơn (sẽ làm sau)
            },
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Lớp Camera
          MobileScanner(
            onDetect: _onDetect, // Hàm callback khi phát hiện mã
          ),

          // Lớp Phủ (Overlay)
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  // Widget để vẽ lớp phủ (khung quét)
  Widget _buildScannerOverlay() {
    double scanBoxSize =
        MediaQuery.of(context).size.width * 0.7; // 70% chiều rộng

    return Container(
      child: Stack(
        children: [
          // Lớp mờ xung quanh
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), // Lớp mờ 50%
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Nền trong suốt
                  ),
                ),
                // Vùng "cắt" ở giữa (khung quét)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanBoxSize,
                    height: scanBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.black, // Màu này không quan trọng
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Viền của khung quét
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanBoxSize,
              height: scanBoxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3), // Viền xanh
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Văn bản hướng dẫn
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 80), // Cách top 80px
              child: Text(
                'Đặt mã QR vào trong khung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
