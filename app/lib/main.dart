import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import các màn hình chính
import 'screen/home_screen.dart';
import 'screen/farmer_main_screen.dart';
import 'screen/transporter_main_screen.dart';
import 'screen/retailer_main_screen.dart';
import 'screen/inspector_main_screen.dart';

void main() async {
  // 1. Giữ màn hình chờ (Native Splash) lại, đừng cho nó tắt vội
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('scan_history');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Biến này sẽ lưu màn hình đích mà user sẽ được đưa tới
  Widget? _destinationScreen;

  @override
  void initState() {
    super.initState();
    // Bắt đầu kiểm tra đăng nhập ngay khi App vừa khởi tạo
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Không cần delay giả vờ nữa, kiểm tra càng nhanh càng tốt!

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    Widget nextScreen;

    // Logic điều hướng (Copy từ SplashScreen cũ sang)
    if (token != null && token.isNotEmpty) {
      print("🚀 Auto Login: $role");
      switch (role) {
        case 'farmer':
          nextScreen = const FarmerMainScreen();
          break;
        case 'transporter':
          nextScreen = const TransporterMainScreen();
          break;
        case 'manager':
        case 'retailer':
          nextScreen = const RetailerMainScreen();
          break;
        case 'moderator':
          nextScreen = const InspectorMainScreen();
          break;
        default:
          nextScreen = const HomeScreen();
      }
    } else {
      print("🚀 Guest Mode");
      nextScreen = const HomeScreen();
    }

    if (!mounted) return;

    setState(() {
      _destinationScreen = nextScreen;
    });

    // 🔥 QUAN TRỌNG: Sau khi đã xác định xong màn hình đích thì mới cho phép gỡ Native Splash
    // Lúc này màn hình sẽ chuyển từ [Logo Đứng Yên] -> [Màn hình App] tức thì.
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriTrace',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Nếu _destinationScreen chưa có (đang check) -> Hiện màn trắng (nhưng thực tế Native Splash đang che nên user không thấy)
      // Nếu đã có -> Vào thẳng màn hình đó
      home: _destinationScreen ?? const Scaffold(backgroundColor: Colors.white),
    );
  }
}
