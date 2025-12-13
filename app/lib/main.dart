import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
// Import các màn hình chính theo vai trò
import 'screen/home_screen.dart';
import 'screen/farmer_main_screen.dart';
import 'screen/transporter_main_screen.dart';
import 'screen/retailer_main_screen.dart';
import 'screen/inspector_main_screen.dart'; // Nếu có Moderator

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriTrace',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// --- TẠO MỘT MÀN HÌNH KHỞI ĐỘNG NHỎ ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Tự động kiểm tra ngay khi mở app
  }

  Future<void> _checkLoginStatus() async {
    // Giả vờ đợi 1 giây cho logo hiện lên đẹp (hoặc bỏ dòng này nếu muốn nhanh)
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    Widget nextScreen;

    // Logic điều hướng dựa trên Token và Role đã lưu
    if (token != null && token.isNotEmpty) {
      print("Đã đăng nhập với vai trò: $role");
      switch (role) {
        case 'farmer':
          nextScreen = const FarmerMainScreen();
          break;
        case 'transporter':
          nextScreen = const TransporterMainScreen();
          break;
        case 'manager': // Hoặc 'retailer' tùy code ông lưu
          nextScreen = const RetailerMainScreen();
          break;
        case 'moderator':
          nextScreen = const InspectorMainScreen(); // Kiểm duyệt viên
          break;
        default:
          nextScreen = const HomeScreen(); // Role lạ thì về trang khách
      }
    } else {
      print("Chưa đăng nhập -> Vào trang khách");
      nextScreen = const HomeScreen();
    }

    if (!mounted) return;

    // Chuyển hướng và xóa màn hình chờ khỏi lịch sử (để bấm Back không quay lại SplashScreen)
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện màn hình chờ (Hiện Logo app)
    return Scaffold(
      backgroundColor: Colors.green, // Màu nền thương hiệu
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.eco, size: 80, color: Colors.white), // Logo cây lúa
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white), // Vòng xoay
          ],
        ),
      ),
    );
  }
}
