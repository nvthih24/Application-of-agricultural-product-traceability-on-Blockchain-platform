import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'product_trace_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Biến kiểm soát xem đã phát hiện mã hay chưa (để tránh quét liên tục)
  bool _isScanCompleted = false;

  void _onDetect(BarcodeCapture capture) async {
    // Thêm async
    if (_isScanCompleted) return;

    final String code = capture.barcodes.first.rawValue ?? "";

    if (code.isNotEmpty) {
      setState(() {
        _isScanCompleted = true; // Khóa lại ngay lập tức
      });

      print("Đã quét mã: $code");

      // Chuyển trang và CHỜ cho đến khi người dùng quay lại
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductTraceScreen(productId: code),
        ),
      );

      // Khi dòng này chạy, nghĩa là người dùng đã bấm Back quay lại đây
      // Lúc này mới mở khóa để quét tiếp
      if (mounted) {
        // Kiểm tra xem màn hình còn tồn tại không
        setState(() {
          _isScanCompleted = false;
        });
      }
    }
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
