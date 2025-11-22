import 'package:flutter/material.dart';
import 'home_screen.dart'; // Nhớ import file vừa tạo

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ Debug đỏ đỏ
      theme: ThemeData(
        // Thiết lập font chữ và màu sắc
        fontFamily: 'Roboto', // Hoặc font nào bạn thích
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C853)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}