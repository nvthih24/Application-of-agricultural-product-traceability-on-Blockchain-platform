import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'product_trace_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final bool isReturnData;
  const QrScannerScreen({super.key, this.isReturnData = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Controller điều khiển camera
  final MobileScannerController controller = MobileScannerController();

  bool _isScanCompleted = false;

  // Hàm xử lý khi quét được mã
  void _onDetect(BarcodeCapture capture) async {
    if (_isScanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String code = barcodes.first.rawValue ?? "";

    if (code.isNotEmpty) {
      setState(() {
        _isScanCompleted = true; // Khóa lại để không quét liên tục
      });

      print("Đã quét mã: $code");

      if (widget.isReturnData) {
        // 1. Trả dữ liệu về (cho Nhập kho)
        Navigator.pop(context, code);
      } else {
        // 2. Chuyển trang Trace (cho Người mua)
        // Tắt camera tạm thời
        await controller.stop();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductTraceScreen(productId: code),
          ),
        );

        // Khi quay lại thì bật lại camera
        if (mounted) {
          await controller.start();
          setState(() {
            _isScanCompleted = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Mã QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // NÚT BẬT ĐÈN FLASH (SỬA LẠI CHO HỢP BẢN MỚI)
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              // Logic mới: Kiểm tra state.torchState
              final isFlashOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: isFlashOn ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          // NÚT ĐỔI CAMERA (SỬA LẠI CHO HỢP BẢN MỚI)
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              // Logic mới: Kiểm tra state.cameraDirection
              final isFront = state.cameraDirection == CameraFacing.front;
              return IconButton(
                icon: Icon(isFront ? Icons.camera_front : Icons.camera_rear),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    double scanBoxSize = MediaQuery.of(context).size.width * 0.7;
    return Container(
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanBoxSize,
                    height: scanBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanBoxSize,
              height: scanBoxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 100),
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
