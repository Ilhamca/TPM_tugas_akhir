import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/theme/app_color.dart';

class PaketSayaPage extends StatefulWidget {
  final int userId;
  final Function({required int paketId, required double lat, required double lng, required String alamat}) onMulaiAntar;

  const PaketSayaPage({super.key, required this.userId, required this.onMulaiAntar});

  @override
  State<PaketSayaPage> createState() => _PaketSayaPageState();
}

class _PaketSayaPageState extends State<PaketSayaPage> {
  bool _isLoading = false;
  String _filter = 'Semua';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _syncFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncFromAPI() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://192.168.18.106/gudang_pintar/api/get_paket_kurir.php?id_kurir=${widget.userId}');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          final box = Hive.box('paketBox');
          await box.clear();
          for (var p in json['data']) {
            await box.put(p['no_resi'], p);
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String noResi, String status) async {
    try {
      final res = await http.post(
        Uri.parse('http://192.168.18.106/gudang_pintar/api/update_status.php'),
        body: {'no_resi': noResi, 'status': status},
      );
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        final box = Hive.box('paketBox');
        final data = Map<String, dynamic>.from(box.get(noResi));
        data['status'] = status;
        await box.put(noResi, data);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    }
  }

  Color _statusColor(String? s) {
    if (s == 'Selesai') return Colors.green;
    if (s == 'Sedang Diantar') return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(child: Text('Paket Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _syncFromAPI),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari resi / penerima...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Semua', 'Di Gudang', 'Sedang Diantar', 'Selesai'].map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.orange.shade100,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('paketBox').listenable(),
              builder: (ctx, Box box, _) {
                var entries = box.toMap().entries.where((e) {
                  final d = e.value as Map;
                  final matchFilter = _filter == 'Semua' || d['status'] == _filter;
                  final matchSearch = _searchQuery.isEmpty ||
                      '${d['no_resi']} ${d['nama_penerima']}'.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchFilter && matchSearch;
                }).toList();

                if (entries.isEmpty && !_isLoading) {
                  return const Center(child: Text('Tidak ada paket'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final d = Map<String, dynamic>.from(entries[i].value);
                    final lat = double.tryParse(d['lat_penerima']?.toString() ?? '') ?? 0.0;
                    final lng = double.tryParse(d['lng_penerima']?.toString() ?? '') ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(d['no_resi'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${d['deskripsi_barang'] ?? '-'} → ${d['nama_penerima']}'),
                            Text(d['alamat_penerima'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(d['status'] ?? '', style: TextStyle(color: _statusColor(d['status']), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: d['status'] == 'Di Gudang'
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 32)),
                              onPressed: () async {
                                await _updateStatus(d['no_resi'], 'Sedang Diantar');
                                widget.onMulaiAntar(paketId: d['id'], lat: lat, lng: lng, alamat: d['alamat_penerima']);
                              },
                              child: const Text('Antar', style: TextStyle(fontSize: 12)),
                            )
                          : d['status'] == 'Sedang Diantar'
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 32)),
                                onPressed: () => _updateStatus(d['no_resi'], 'Selesai'),
                                child: const Text('Selesai', style: TextStyle(fontSize: 12)),
                              )
                            : const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}