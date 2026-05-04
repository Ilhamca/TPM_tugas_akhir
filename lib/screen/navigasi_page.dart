import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class NavigasiPage extends StatefulWidget {
  final double? targetLat;
  final double? targetLng;
  final String? targetAlamat;
  final int? activePaketId;

  const NavigasiPage({super.key, this.targetLat, this.targetLng, this.targetAlamat, this.activePaketId});

  @override
  State<NavigasiPage> createState() => _NavigasiPageState();
}

class _NavigasiPageState extends State<NavigasiPage> {
  Position? _kurirPos;
  String _weatherStatus = '-';
  double _temp = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _kurirPos = pos);
      _fetchWeather(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('GPS error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      final r = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true'));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body)['current_weather'];
        setState(() {
          _temp = d['temperature'];
          _weatherStatus = _codeToText(d['weathercode']);
        });
      }
    } catch (_) {}
  }

  String _codeToText(int code) {
    if (code == 0) return '☀️ Cerah';
    if (code <= 3) return '⛅ Berawan';
    if (code <= 48) return '🌫️ Berkabut';
    if (code <= 67) return '🌧️ Hujan';
    if (code <= 82) return '⛈️ Hujan Deras';
    return '⛈️ Badai';
  }

  double _hitungJarak() {
    if (_kurirPos == null || widget.targetLat == null) return 0;
    return Geolocator.distanceBetween(_kurirPos!.latitude, _kurirPos!.longitude, widget.targetLat!, widget.targetLng!) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final hasTarget = widget.targetLat != null && widget.targetLng != null;
    final kurirLL = _kurirPos != null ? LatLng(_kurirPos!.latitude, _kurirPos!.longitude) : null;
    final targetLL = hasTarget ? LatLng(widget.targetLat!, widget.targetLng!) : null;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Navigasi Armada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (hasTarget) Text(widget.targetAlamat ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _getLocation),
              ],
            ),
          ),

          // Info bar cuaca + jarak
          if (_kurirPos != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_weatherStatus  $_temp°C', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (hasTarget) Text('📍 ${_hitungJarak().toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),

          if (_isLoading) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),

          // PETA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _kurirPos == null
                  ? const Center(child: Text('Mendapatkan lokasi GPS...', style: TextStyle(color: Colors.grey)))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: kurirLL!,
                        initialZoom: hasTarget ? 12 : 14,
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.tugas_akhir'),
                        MarkerLayer(markers: [
                          Marker(
                            point: kurirLL,
                            width: 40, height: 40,
                            child: const Icon(Icons.local_shipping, color: Colors.blue, size: 36),
                          ),
                          if (targetLL != null)
                            Marker(
                              point: targetLL,
                              width: 40, height: 40,
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                        ]),
                        if (targetLL != null)
                          PolylineLayer(polylines: [
                            Polyline(points: [kurirLL, targetLL], strokeWidth: 3, color: Colors.orange),
                          ]),
                      ],
                    ),
              ),
            ),
          ),

          if (!hasTarget)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Pilih paket di tab "Paket Saya" lalu tekan Antar untuk navigasi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}