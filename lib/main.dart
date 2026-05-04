import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:tugas_akhir/screen/login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tugas_akhir/constants/string_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tugas_akhir/services/notification_services.dart';
import 'package:flutter/services.dart';

class HiveDatabaseHelper {
  static const secureStorage = FlutterSecureStorage();
  static const String _boxName = 'gudangPintarSecureBox';

  static Future<void> initHiveAndOpenBox() async {
    // 1. Inisialisasi Hive untuk Flutter
    await Hive.initFlutter();

    // 2. Mengecek apakah kunci enkripsi sudah ada di perangkat
    String? encryptionKeyString = await secureStorage.read(
      key: 'hive_encryption_key',
    );

    if (encryptionKeyString == null) {
      // 3. Jika belum ada, buat kunci 256-bit baru secara kriptografis
      final key = Hive.generateSecureKey();

      // Simpan kunci tersebut ke penyimpanan aman (Keystore/Keychain)
      await secureStorage.write(
        key: 'hive_encryption_key',
        value: base64UrlEncode(key),
      );

      encryptionKeyString = base64UrlEncode(key);
    }

    // 4. Decode string menjadi list of bytes
    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

    // 5. Buka kotak Hive dengan Cipher AES
    await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    );

    debugPrint('Database Hive Terenkripsi Berhasil Dibuka!');
  }

  //Notification
  static Future<void> initNotifications() async {
    await NotificationService().init();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Open the Hive box to store items
  await Hive.openBox(StringConstants.hiveBox);

  // Login Encryption
  await HiveDatabaseHelper.initHiveAndOpenBox();

  // Database barang
  await Hive.openBox('inventoryBox');

  // Initialize notifications
  await HiveDatabaseHelper.initNotifications();

  // Mengunci orientasi aplikasi hanya pada posisi Portrait (Tegak)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
