import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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

  // Daftar kategori barang gudang
  final List<Map<String, dynamic>> _itemTypes = [
    {'type': 'Elektronik', 'icon': Icons.computer, 'color': Colors.blue},
    {'type': 'Makanan', 'icon': Icons.fastfood, 'color': Colors.green},
    {'type': 'Pakaian', 'icon': Icons.checkroom, 'color': Colors.orange},
  ];

  late Map<String, dynamic> _currentItem;

  @override
  void initState() {
    super.initState();
    _generateRandomItem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateRandomItem() {
    final random = Random();
    _currentItem = _itemTypes[random.nextInt(_itemTypes.length)];
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _generateRandomItem();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _endGame();
        }
      });
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
              const Text('Barang berhasil disortir.', style: TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Kembali ke profil
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
        title: const Text('Mini Game: Sortir Gudang'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- HEADER SKOR & WAKTU ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text('Skor: $_score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _timeLeft <= 5 ? Colors.red.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Text('Waktu: ${_timeLeft}s', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : Colors.black87)),
                  ),
                ],
              ),
              const Spacer(),

              // --- AREA BARANG MUNCUL (DRAGGABLE) ---
              if (_isPlaying)
                Draggable<String>(
                  data: _currentItem['type'],
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildItemCard(_currentItem, isDragging: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildItemCard(_currentItem),
                  ),
                  child: _buildItemCard(_currentItem),
                )
              else
                Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Simulasi Sortir', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // --- AREA KOTAK TARGET (DRAG TARGET) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _itemTypes.map((bin) {
                  return DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      bool isTargeted = candidateData.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isTargeted ? bin['color'].withOpacity(0.3) : bin['color'].withOpacity(0.1),
                          border: Border.all(color: bin['color'], width: isTargeted ? 4 : 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(bin['icon'], size: 40, color: bin['color']),
                            const SizedBox(height: 8),
                            Text(bin['type'], style: TextStyle(fontWeight: FontWeight.bold, color: bin['color'])),
                          ],
                        ),
                      );
                    },
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) {
                      // Jika barang dijatuhkan di kotak yang benar
                      if (details.data == bin['type']) {
                        setState(() {
                          _score += 10; // Tambah 10 poin
                          _generateRandomItem();
                        });
                      } else {
                        setState(() {
                          _score -= 5; // Kurangi 5 poin jika salah
                          _generateRandomItem();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Desain kartu barang yang bisa digeser
  Widget _buildItemCard(Map<String, dynamic> item, {bool isDragging = false}) {
    return Container(
      width: isDragging ? 130 : 120,
      height: isDragging ? 130 : 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDragging ? 0.4 : 0.2),
            blurRadius: isDragging ? 20 : 10,
            spreadRadius: isDragging ? 5 : 0,
            offset: Offset(0, isDragging ? 10 : 5),
          )
        ],
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item['icon'], size: 50, color: item['color']),
          const SizedBox(height: 8),
          Text(item['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}