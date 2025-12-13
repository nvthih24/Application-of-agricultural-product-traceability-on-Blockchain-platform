import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart'; // Để dùng tính năng copy vào clipboard

class NotificationCheckScreen extends StatefulWidget {
  const NotificationCheckScreen({super.key});

  @override
  State<NotificationCheckScreen> createState() =>
      _NotificationCheckScreenState();
}

class _NotificationCheckScreenState extends State<NotificationCheckScreen> {
  String? _token = "Đang lấy token...";
  String _messageStatus = "Chưa có tin nhắn mới";

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Xin quyền thông báo
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Người dùng đã cấp quyền thông báo');

      // 2. Lấy Token
      String? token = await messaging.getToken();
      setState(() {
        _token = token;
      });
      print("🔥 FCM TOKEN: $token"); // In ra console để check
    } else {
      setState(() {
        _token = "Người dùng từ chối quyền thông báo";
      });
    }

    // 3. Lắng nghe tin nhắn khi đang mở App (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Nhận tin nhắn foreground: ${message.notification?.title}');
      setState(() {
        _messageStatus =
            "Tin mới: ${message.notification?.title}\n${message.notification?.body}";
      });

      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔔 ${message.notification!.title}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test FCM Token")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_active,
              size: 60,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "FCM Device Token:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Khu vực hiển thị Token có thể copy
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: SelectableText(
                _token ?? "Đang tải...",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                if (_token != null) {
                  Clipboard.setData(ClipboardData(text: _token!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã copy Token!")),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text("Copy Token"),
            ),

            const Divider(height: 40),
            const Text(
              "Trạng thái nhận tin:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _messageStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
