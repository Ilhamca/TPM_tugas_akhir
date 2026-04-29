import 'package:flutter/material.dart';
import 'package:tugas_akhir/screen/login_page.dart';
import 'package:tugas_akhir/services/notification_services.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username});

  final String username;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${widget.username}!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              child: const Text('Logout'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Contoh penggunaan notifikasi instan
                NotificationService().showInstantNotification(
                  title: 'Hello, ${widget.username}!',
                  body: 'This is an instant notification.',
                );
              },
              child: const Text('Show Instant Notification'),
            ),
          ],
        ),
      ),
    );
  }
}