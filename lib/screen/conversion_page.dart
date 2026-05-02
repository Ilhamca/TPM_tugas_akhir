import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage> {
  // === VARIABEL KONVERSI WAKTU ===
  late Timer _timer;
  DateTime _nowUtc = DateTime.now().toUtc();

  // === VARIABEL KONVERSI MATA UANG ===
  final TextEditingController _currencyController = TextEditingController();
  double _idrValue = 0.0;

  // Asumsi nilai tukar (bisa diganti dengan API jika diperlukan nanti)
  final double _usdRate = 16200.0; // 1 USD ke IDR
  final double _eurRate = 17500.0; // 1 EUR ke IDR
  final double _gbpRate = 20500.0; // 1 GBP ke IDR

  @override
  void initState() {
    super.initState();
    // Memperbarui waktu setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _nowUtc = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Mencegah memory leak
    _currencyController.dispose();
    super.dispose();
  }

  // Helper untuk memformat jam agar selalu 2 digit (contoh: 09:05:01)
  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    String s = time.second.toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung zona waktu sesuai kriteria tugas
    DateTime timeLondon = _nowUtc.add(const Duration(hours: 0)); // GMT/UTC+0
    DateTime timeWIB = _nowUtc.add(const Duration(hours: 7));    // UTC+7
    DateTime timeWITA = _nowUtc.add(const Duration(hours: 8));   // UTC+8
    DateTime timeWIT = _nowUtc.add(const Duration(hours: 9));    // UTC+9

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.public, size: 36, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemasok Internasional',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Konversi Waktu & Estimasi Biaya Impor',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- BAGIAN 1: KONVERSI WAKTU ---
            const Text(
              '🕒 Jam Operasional Gudang & Pemasok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildTimeCard('London (GMT)', _formatTime(timeLondon), Colors.blueGrey),
                _buildTimeCard('Jakarta (WIB)', _formatTime(timeWIB), Colors.green),
                _buildTimeCard('Makassar (WITA)', _formatTime(timeWITA), Colors.teal),
                _buildTimeCard('Jayapura (WIT)', _formatTime(timeWIT), Colors.orange),
              ],
            ),

            const SizedBox(height: 32),

            // --- BAGIAN 2: KONVERSI MATA UANG ---
            const Text(
              '💱 Kalkulator Estimasi Biaya Impor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _currencyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Masukkan Nominal Rupiah (IDR)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _idrValue = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildCurrencyResult('Dolar Amerika (USD)', _idrValue / _usdRate, '\$'),
                    _buildCurrencyResult('Euro (EUR)', _idrValue / _eurRate, '€'),
                    _buildCurrencyResult('Pound Britania (GBP)', _idrValue / _gbpRate, '£'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk UI Jam
  Widget _buildTimeCard(String location, String timeStr, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(timeStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // Widget pembantu untuk UI Hasil Konversi Uang
  Widget _buildCurrencyResult(String currencyName, double convertedValue, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currencyName, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '$symbol ${convertedValue.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}