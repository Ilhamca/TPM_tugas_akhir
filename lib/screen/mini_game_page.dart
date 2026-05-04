import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> {
  int _score = 0;
  int _timeLeft = 30; // Waktu bermain 30 detik
  Timer? _timer;
  bool _isPlaying = false;

  // --- Variabel Sensor & Fisika Game ---
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _itemX = 0.0; // Koordinat horizontal (-1.0 Kiri s/d 1.0 Kanan)
  double _itemY = 0.0; // Koordinat vertikal (-1.0 Atas s/d 1.0 Bawah) - Mulai dari tengah

  // 2 Kategori dengan nuansa warna Oranye
  final List<Map<String, dynamic>> _itemTypes = [
    {'type': 'Elektronik', 'icon': Icons.computer, 'color': Colors.orange.shade400},      // Kotak ATAS
    {'type': 'Makanan', 'icon': Icons.fastfood, 'color': Colors.deepOrange.shade600}, // Kotak BAWAH
  ];

  late Map<String, dynamic> _currentItem;

  @override
  void initState() {
    super.initState();
    _generateRandomItem();
    _initSensor();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSubscription?.cancel(); // Wajib dimatikan agar hemat baterai
    super.dispose();
  }

  // --- LOGIKA SENSOR ACCELEROMETER ---
  void _initSensor() {
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isPlaying && mounted) {
        setState(() {
          // Menggerakkan item berdasarkan kemiringan HP
          _itemX -= event.x * 0.04; 
          _itemY += event.y * 0.04;

          // Membatasi agar item tidak keluar dari sisi layar
          if (_itemX < -1.0) _itemX = -1.0;
          if (_itemX > 1.0) _itemX = 1.0;
          if (_itemY < -1.0) _itemY = -1.0;
          if (_itemY > 1.0) _itemY = 1.0;

          // Deteksi "Drop" saat item menyentuh ujung ATAS atau BAWAH layar
          if (_itemY <= -0.8) {
            _checkDrop(0); // 0 = Kotak Atas
          } else if (_itemY >= 0.8) {
            _checkDrop(1); // 1 = Kotak Bawah
          }
        });
      }
    });
  }

  void _checkDrop(int targetIndex) {
    String targetType = _itemTypes[targetIndex]['type'];

    // Hitung skor
    if (_currentItem['type'] == targetType) {
      _score += 10; // Benar (+10)
    } else {
      _score -= 40; // SALAH KOTAK: Hukuman berat (-40)
    }

    // Munculkan barang baru
    _generateRandomItem();
  }

  void _generateRandomItem() {
    final random = Random();
    _currentItem = _itemTypes[random.nextInt(_itemTypes.length)];
    // Kembalikan posisi barang tepat ke tengah layar setiap kali muncul
    _itemX = 0.0;
    _itemY = 0.0;
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _generateRandomItem();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _endGame();
          }
        });
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
    });
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Waktu Habis!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
              const SizedBox(height: 16),
              Text('Skor Anda: $_score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _score < 0 ? 'Banyak barang hancur! Hati-hati.' : 'Sortir selesai!', 
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Kembali ke halaman profil
              },
              child: const Text('Keluar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _startGame();
              },
              child: const Text('Main Lagi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sortir Gudang (Sensor Mode)'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER SKOR & WAKTU ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text('Skor: $_score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _timeLeft <= 5 ? Colors.red.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text('Waktu: ${_timeLeft}s', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : Colors.black87)),
                  ),
                ],
              ),
            ),

            // --- AREA BERMAIN (TILT & PHYSICS) ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Stack(
                  children: [
                    // KOTAK TARGET DI ATAS LAYAR
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildBin(_itemTypes[0]),
                      ),
                    ),

                    // KOTAK TARGET DI BAWAH LAYAR
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildBin(_itemTypes[1]),
                      ),
                    ),

                    // BARANG YANG BERGERAK SESUAI SENSOR HP
                    if (_isPlaying)
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 100), // Animasi agar mulus
                        alignment: Alignment(_itemX, _itemY),
                        child: _buildItemCard(_currentItem),
                      ),

                    // TOMBOL MULAI (Jika belum main)
                    if (!_isPlaying)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.screen_rotation, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Miringkan HP Anda untuk\nmenggeser barang ke kotak Atas / Bawah!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _startGame,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Mulai Bermain', style: TextStyle(fontSize: 18)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Desain kotak penampung
  Widget _buildBin(Map<String, dynamic> bin) {
    return Container(
      width: 140, // Dibuat lebih lebar karena letaknya di tengah atas/bawah
      height: 110,
      decoration: BoxDecoration(
        color: bin['color'].withValues(alpha: 0.1),
        border: Border.all(color: bin['color'], width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(bin['icon'], size: 40, color: bin['color']),
          const SizedBox(height: 4),
          Text(bin['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: bin['color'])),
        ],
      ),
    );
  }

  // Desain kardus barang yang melayang
  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: item['color'].withValues(alpha: 0.5), width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item['icon'], size: 40, color: item['color']),
          const SizedBox(height: 4),
          Text(item['type'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}