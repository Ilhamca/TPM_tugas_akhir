import 'package:flutter/material.dart';

class AppColors {
  // Warna Utama: Slate/Abu-abu Biru (Kalem, profesional, tidak menyilaukan)
  static const Color primary = Color(0xFF475569);
  static const Color primaryDark = Color(0xFF334155);
  static const Color primaryLight = Color(0xFFF1F5F9);

  // Warna Aksen: Muted Teal (Memberikan sedikit warna penegas untuk tombol tanpa terlalu mencolok)
  static const Color accent = Color(0xFF0F766E);

  // Status Logistik (Diturunkan intensitas terangnya agar tidak terlihat "neon")
  static const Color success = Color(0xFF059669); // Hijau zamrud agak gelap
  static const Color warning = Color(0xFFD97706); // Kuning amber gelap
  static const Color error = Color(0xFFDC2626); // Merah bata

  // Latar Belakang & Elemen Teks (Menghindari hitam pekat murni)
  static const Color bg = Color(
    0xFFF8FAFC,
  ); // Latar belakang aplikasi (abu-abu sangat muda)
  static const Color cardBg = Color(0xFFFFFFFF); // Latar belakang kartu
  static const Color textPrimary = Color(
    0xFF334155,
  ); // Teks abu-abu gelap, lebih nyaman dari hitam #000000
  static const Color textSecondary = Color(0xFF64748B); // Teks label/keterangan
  static const Color border = Color(0xFFE2E8F0); // Garis pemisah

  // Hyperlink (Warna yang sedikit lebih cerah dari warna utama untuk menarik perhatian tanpa terlalu mencolok)
  static const Color link = Color(
    0xFF2563EB,
  ); // Biru yang lebih cerah untuk tautan

  static const List<Color> menuColors = [
    Color.fromARGB(255, 80, 129, 234), // Data Kelompok - biru
    Color(0xFF06B6D4), // Ganti Tanggal Lahir - cyan
    Color(0xFF10B981), // Calculator - hijau
    Color(0xFFF59E0B), // Ganjil/Genap - kuning
    Color(0xFFEF4444), // Stopwatch - merah
    Color(0xFF8B5CF6), // Total Angka - ungu
    Color(0xFFEC4899), // Rumus Piramid - pink
    Color(0xFF3B82F6), // Konversi Hari Weton - biru muda
    Color(0xFF14B8A6), // Konversi Hijriah-Masehi - teal
    Color.fromARGB(255, 109, 37, 37), // Konversi Tanggal Saka - coklat
  ];
}
