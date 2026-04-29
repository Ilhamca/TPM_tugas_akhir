import 'package:flutter/material.dart';
import 'package:tugas_akhir/screen/login_page.dart';
import 'package:tugas_akhir/services/notification_services.dart';
import 'package:tugas_akhir/controller/controller.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username});

  final String username;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan berdasarkan index yang dipilih
  late final List<Widget> _pages = [
    _buildDashboardGudang(),
    _buildProfilPage(),
    _buildSaranTPMPage(),
    _buildPengaturanPage(),
  ];

  // Fungsi untuk menangani navigasi bawah
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Dialog Konfirmasi Logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // Tutup dialog
                Navigator.pop(context);
                // Arahkan kembali ke halaman Login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan berubah sesuai dengan index yang aktif
      body: _pages[_selectedIndex],

      // Implementasi Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Gunakan fixed agar semua menu muncul meskipun > 3
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Saran TPM',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET HALAMAN 1: BERANDA / DASHBOARD
  // ==========================================
  Widget _buildDashboardGudang() {
    return SafeArea(
      child: Center(
        // Menggunakan SingleChildScrollView agar tidak overflow jika layar kecil
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warehouse, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Dashboard Gudang Pintar\nSelamat datang, ${widget.username}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // 1. Tombol Notifikasi yang diintegrasikan dari kode lama Anda
              ElevatedButton.icon(
                onPressed: () {
                  NotificationService().showInstantNotification(
                    title: 'Hello, ${widget.username}!',
                    body: 'This is an instant notification.',
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show Instant Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HALAMAN 2: PROFIL (WAJIB ADA GAMBAR)
  // ==========================================
  Widget _buildProfilPage() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ilham Cesario Putra Wippri',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mahasiswa Informatika\nUPN Veteran Yogyakarta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HALAMAN 3: SARAN DAN KESAN TPM
  // ==========================================
  Widget _buildSaranTPMPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saran & Kesan Mata Kuliah',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Teknologi dan Pemrograman Mobile (TPM)',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Tuliskan kesan dan saran Anda selama mengikuti mata kuliah ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saran berhasil dikirim! Terima kasih.'),
                    ),
                  );
                },
                child: const Text('Kirim Saran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HALAMAN 4: PENGATURAN, DEBUG, & LOGOUT
  // ==========================================
  Widget _buildPengaturanPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan & Debug',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola pengaturan aplikasi dan data Anda',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: _showLogoutDialog,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Hapus Semua Data User (Debug)'),
              onPressed: () async {
                await AppController.clearAllUserData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database berhasil dikosongkan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
