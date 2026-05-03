import 'package:flutter/material.dart';
import 'package:tugas_akhir/screen/inventory_page.dart';
import 'package:tugas_akhir/screen/conversion_page.dart';
import 'package:tugas_akhir/screen/shipping_page.dart';
import 'package:tugas_akhir/screen/sensor_page.dart';
import 'package:tugas_akhir/screen/profile_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username});

  final String username;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  // Daftar 5 halaman utama aplikasi Gudang Pintar
  late final List<Widget> _pages = [
    InventoryPage(username: widget.username), // 0: Beranda
    const ConversionPage(),                   // 1: Pemasok Global
    const ShippingPage(),                     // 2: LBS Armada
    const SensorPage(),                       // 3: Uji Sensor Kardus
    const ProfilePage(),                      // 4: Profil & Pengaturan
  ];

  // Fungsi untuk menangani navigasi bawah
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan merender Widget sesuai dengan tab yang sedang aktif
      body: _pages[_selectedIndex],

      // Implementasi Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Wajib fixed jika item >= 4
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public), 
            label: 'Global'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping), 
            label: 'Armada'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing), 
            label: 'Sensor'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profil' 
          ),
        ],
      ),
    );
  }
}