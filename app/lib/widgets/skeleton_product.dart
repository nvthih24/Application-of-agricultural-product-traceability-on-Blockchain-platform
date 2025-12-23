import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonProduct extends StatelessWidget {
  const SkeletonProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Giả lập cái Ảnh
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
            ),
            // Giả lập dòng Tên và Giá
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 80, color: Colors.white), // Tên
                  const SizedBox(height: 8),
                  Container(height: 10, width: 60, color: Colors.white), // Giá
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
