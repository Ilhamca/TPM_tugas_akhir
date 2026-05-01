import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:tugas_akhir/screen/menu_page.dart';
import 'package:tugas_akhir/screen/register_page.dart';
import 'package:tugas_akhir/services/biometric_auth_service.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _lastLoginUsernameKey = 'last_login_username';

  final BiometricAuthService _biometricService = BiometricAuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginFailed = false;
  bool _obscurePassword = true;
  bool _isBiometricSupported = false;
  bool _isAuthenticatingBiometric = false;
  String? _storedUsername;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load biometric availability status dan username terakhir yang login
  Future<void> _loadBiometricState() async {
    final bool biometricAvailable = await _biometricService
        .isBiometricAvailable();
    final String? storedUsername = await _secureStorage.read(
      key: _lastLoginUsernameKey,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      // Menjamin tombol tetap muncul jika biometrik tersedia ATAU user sudah pernah login (fallback emulator)
      _isBiometricSupported = biometricAvailable || storedUsername != null;
      _storedUsername = storedUsername;
    });
  }

  /// Login dengan username dan password biasa
  Future<void> _loginWithPassword() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Username dan password tidak boleh kosong');
      setState(() {
        _isLoginFailed = true;
      });
      return;
    }

    try {
      final Box<dynamic> box = Hive.box('gudangPintarSecureBox');
      final dynamic matchedUserData = box.get(username);

      bool isMatch = false;
      if (matchedUserData != null) {
        final String hashedPassword = sha256
            .convert(utf8.encode(password))
            .toString();
        if (matchedUserData['password'] == hashedPassword) {
          isMatch = true;
        }
      }

      if (!isMatch) {
        _showErrorSnackBar('Username atau password salah');
        setState(() {
          _isLoginFailed = true;
        });
        return;
      }

      // Simpan username terakhir untuk biometrik di lain waktu
      await _rememberLastLoginUsername(username);
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoginFailed = false;
        _storedUsername = username;
        _isBiometricSupported = true;
      });

      _goToMenuPage(username);
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  /// Login dengan biometrik (fingerprint / face ID)
  Future<void> _loginWithBiometrics() async {
    if (_isAuthenticatingBiometric) {
      return;
    }

    if (_storedUsername == null || _storedUsername!.isEmpty) {
      _showErrorSnackBar('Belum ada akun yang tersimpan untuk biometrik');
      return;
    }

    setState(() {
      _isAuthenticatingBiometric = true;
    });

    try {
      final bool authenticated = await _biometricService.authenticate(
        reason: 'Konfirmasi identitas untuk masuk ke Gudang Pintar',
      );

      if (!mounted) {
        return;
      }

      if (!authenticated) {
        return;
      }

      // Validasi akun tersimpan masih ada di database
      final Box<dynamic> box = Hive.box('gudangPintarSecureBox');
      final dynamic storedUserData = box.get(_storedUsername!);
      if (storedUserData == null) {
        _showErrorSnackBar(
          'Akun tersimpan tidak ditemukan. Silakan login ulang.',
        );
        setState(() {
          _isBiometricSupported = false;
        });
        await _secureStorage.delete(key: _lastLoginUsernameKey);
        return;
      }

      _goToMenuPage(_storedUsername!);
    } catch (e) {
      if (!mounted) {
        return;
      }
      // --- MULAI PENERJEMAHAN ERROR ---
      String errorMessage = 'Biometrik tidak tersedia: $e';
      String errorString = e.toString();

      // Jika errornya karena tidak ada PIN/Sandi (kasus awam)
      if (errorString.contains('noCredentialsSet') ||
          errorString.contains('NotEnrolled')) {
        errorMessage =
            'Ups! HP Anda belum dilengkapi kunci layar. Silakan buat PIN atau Pola di Pengaturan HP Anda terlebih dahulu.';
      }
      // Tambahan bonus: Jika error karena terlalu sering salah sidik jari
      else if (errorString.contains('LockedOut')) {
        errorMessage =
            'Terlalu banyak percobaan salah. Sensor sidik jari dikunci sementara oleh sistem HP Anda.';
      }
      // ---------------------------------
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticatingBiometric = false;
        });
      }
    }
  }

  /// Simpan username ke secure storage untuk dipakai login biometrik
  Future<void> _rememberLastLoginUsername(String username) async {
    await _secureStorage.write(key: _lastLoginUsernameKey, value: username);
  }

  /// Navigasi ke halaman menu
  void _goToMenuPage(String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MenuPage(username: username)),
    );
  }

  /// Tampilkan error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Widget header (logo, judul, subtitle)
  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 1),
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.32),
                      Colors.white.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 46,
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Text(
          'Gudang Pintar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Teknologi & Pemrogaman Mobile',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Widget form login (input fields + buttons)
  Widget _buildLoginForm() {
    return ClipPath(
      clipBehavior: Clip.antiAlias,
      clipper: WaveClipperOne(reverse: true),
      child: Container(
        width: double.infinity,
        color: AppColors.primaryLight,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.bg),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Masuk',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Silakan login untuk melanjutkan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                if (_isLoginFailed) _buildErrorMessage(),
                const SizedBox(height: 28),
                _buildPrimaryLoginButton(),
                if (_isBiometricSupported) ...[
                  const SizedBox(height: 12),
                  _buildBiometricLoginButton(),
                  if (_storedUsername == null || _storedUsername!.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Login biometrik akan aktif setelah login password pertama.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                _buildRegisterPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget input username
  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Username',
        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isLoginFailed ? AppColors.error : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  /// Widget input password
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _loginWithPassword(),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isLoginFailed ? AppColors.error : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  /// Widget pesan error login
  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 14),
          const SizedBox(width: 4),
          const Text(
            // Penambahan const
            'Username atau password salah',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Tombol login dengan password
  Widget _buildPrimaryLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loginWithPassword,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
        ),
        child: const Text(
          'Masuk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Tombol login dengan biometrik
  Widget _buildBiometricLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isAuthenticatingBiometric ? null : _loginWithBiometrics,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
        icon: _isAuthenticatingBiometric
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.fingerprint),
        label: Text(
          _isAuthenticatingBiometric
              ? 'Memverifikasi biometrik...'
              : 'Masuk dengan biometrik',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Widget link ke halaman register
  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Belum punya akun? ',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          child: const Text(
            'Daftar',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.link,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // PENGGUNAAN CUSTOMSCROLLVIEW UNTUK MENGATASI OVERFLOW
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Expanded(flex: 1, child: _buildHeader()),
                  Expanded(flex: 3, child: _buildLoginForm()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
