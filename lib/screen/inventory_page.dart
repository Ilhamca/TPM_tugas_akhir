import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tugas_akhir/services/notification_services.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.username});
  final String username;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<dynamic> _selectedKeys = {}; // Menyimpan ID barang yang dicentang

  @override
  void initState() {
    super.initState();
    _initDummyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Membuat data awal jika database gudang masih kosong
  Future<void> _initDummyData() async {
    var box = Hive.box('inventoryBox');
    if (box.isEmpty) {
      await box.put('item_1', {'name': 'Kardus Besar', 'stock': 15});
      await box.put('item_2', {'name': 'Lakban Coklat', 'stock': 8});
      await box.put('item_3', {'name': 'Plastik Bubble Wrap', 'stock': 6});
      await box.put('item_4', {'name': 'Gunting Baja', 'stock': 20});
    }
  }

  // Logika Menambah Stok
  void _increaseStock(dynamic key, Map data) {
    var box = Hive.box('inventoryBox');
    box.put(key, {'name': data['name'], 'stock': data['stock'] + 1});
  }

  // Logika Mengurangi Stok & Memicu Notifikasi
  void _decreaseStock(dynamic key, Map data) {
    if (data['stock'] > 0) {
      var box = Hive.box('inventoryBox');
      int newStock = data['stock'] - 1;
      
      box.put(key, {'name': data['name'], 'stock': newStock});

      // FITUR NOTIFIKASI: Memicu peringatan jika stok kritis (< 5)
      if (newStock < 5) {
        NotificationService().showInstantNotification(
          title: '⚠️ Peringatan Stok Tipis!',
          body: 'Stok barang "${data['name']}" hanya tersisa $newStock.',
        );
      }
    }
  }

  // Logika Pemilihan (Selection) untuk menghapus barang
  void _deleteSelectedItems() {
    var box = Hive.box('inventoryBox');
    box.deleteAll(_selectedKeys);
    setState(() {
      _selectedKeys.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barang terpilih berhasil dihapus'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.warehouse, size: 40, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventaris Gudang',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Admin: ${widget.username}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Tombol Hapus (Muncul jika ada barang yang dipilih)
                if (_selectedKeys.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelectedItems,
                    tooltip: 'Hapus barang terpilih',
                  ),
              ],
            ),
          ),

          // FITUR PENCARIAN (Search Bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Barang dengan Hive ValueListenableBuilder
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('inventoryBox').listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('Gudang kosong.'));
                }

                // Filter data berdasarkan pencarian
                var filteredEntries = box.toMap().entries.where((entry) {
                  var itemData = entry.value as Map;
                  var itemName = itemData['name'].toString().toLowerCase();
                  return itemName.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredEntries.isEmpty) {
                  return const Center(child: Text('Barang tidak ditemukan.'));
                }

                return ListView.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    var key = filteredEntries[index].key;
                    var data = filteredEntries[index].value as Map;
                    bool isSelected = _selectedKeys.contains(key);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        // FITUR PEMILIHAN (Checkbox)
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedKeys.add(key);
                              } else {
                                _selectedKeys.remove(key);
                              }
                            });
                          },
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Sisa Stok: ${data['stock']}',
                          style: TextStyle(
                            color: data['stock'] < 5 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                              onPressed: () => _decreaseStock(key, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => _increaseStock(key, data),
                            ),
                          ],
                        ),
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