import 'package:flutter/material.dart';
import 'package:tugas_akhir/screen/paket_saya_page.dart';
import 'package:tugas_akhir/screen/navigasi_page.dart';
import 'package:tugas_akhir/screen/conversion_page.dart';
import 'package:tugas_akhir/screen/ai_helper_page.dart';
import 'package:tugas_akhir/screen/profile_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username, required this.userId});
  final String username;
  final int userId;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  int? _activePaketId;      // ID paket yang sedang diantar
  double? _targetLat;
  double? _targetLng;
  String? _targetAlamat;

  void _onPaketMulaiAntar({required int paketId, required double lat, required double lng, required String alamat}) {
    setState(() {
      _activePaketId = paketId;
      _targetLat = lat;
      _targetLng = lng;
      _targetAlamat = alamat;
      _selectedIndex = 1; // Pindah ke tab Navigasi
    });
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PaketSayaPage(userId: widget.userId, onMulaiAntar: _onPaketMulaiAntar),
          NavigasiPage(targetLat: _targetLat, targetLng: _targetLng, targetAlamat: _targetAlamat, activePaketId: _activePaketId),
          const ConversionPage(),
          const AiHelperPage(),
          const ProfilePage(),
        ],
      ),
    );
  }
}