// login_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logbook_app_069/features/auth/login_controller.dart';
import 'package:logbook_app_069/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // State untuk fitur baru
  bool _isPasswordVisible = false;
  int _loginAttempts = 0;
  bool _isLoginDisabled = false;
  Timer? _timer;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleLogin() {
    if (_isLoginDisabled) return;

    String user = _userController.text;
    String pass = _passController.text;

    // Validasi field tidak boleh kosong
    if (user.isEmpty || pass.isEmpty) {
      _showError("Username dan Password tidak boleh kosong!");
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      // Reset percobaan jika berhasil
      setState(() {
        _loginAttempts = 0;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Di sini kita kirimkan variabel 'user' ke parameter 'username' di CounterView
          builder: (context) => CounterView(username: user),
        ),
      );
    } else {
      setState(() {
        _loginAttempts++;
      });
      _showError("Login Gagal! Percobaan ke-$_loginAttempts.");

      // Logika untuk menonaktifkan tombol
      if (_loginAttempts >= 3) {
        setState(() {
          _isLoginDisabled = true;
        });
        _timer = Timer(const Duration(seconds: 10), () {
          setState(() {
            _isLoginDisabled = false;
            _loginAttempts = 0; // Reset setelah 10 detik
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _timer?.cancel(); // Batalkan timer jika widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);
    const accentDark = Color(0xFFD97706);
    const darkText = Color(0xFF1F2937);
    const muted = Color(0xFF6B7280);
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Warm amber gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFBBF24)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Decorative glow orbs ──
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.35), accent.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenH * 0.08,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFD97706).withOpacity(0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenH * 0.35,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFF59E0B).withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Konten utama ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: screenH * 0.04),

                    // ── Ikon glass circle ──
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 44, color: Color(0xFFD97706)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Logbook App",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Catat aktivitas harian Anda",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),

                    SizedBox(height: screenH * 0.035),

                    // ── Glassmorphism card (white glass) ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.login_rounded, size: 20, color: accent),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Masuk Akun",
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Silakan masukkan kredensial Anda untuk melanjutkan",
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                              ),

                              const SizedBox(height: 22),

                              // Username
                              _buildLabel("Username"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _userController,
                                hint: "Masukkan username",
                                icon: Icons.person_outline_rounded,
                              ),

                              const SizedBox(height: 18),

                              // Password
                              _buildLabel("Password"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _passController,
                                hint: "Masukkan password",
                                icon: Icons.lock_outline_rounded,
                                obscure: !_isPasswordVisible,
                                suffix: IconButton(
                                  splashRadius: 20,
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: const Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),

                              // Percobaan gagal
                              if (_loginAttempts > 0 && !_isLoginDisabled) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFFCA5A5)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Percobaan gagal: $_loginAttempts/3",
                                        style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),

                              // Tombol Masuk
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: _isLoginDisabled
                                        ? null
                                        : const LinearGradient(
                                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                    color: _isLoginDisabled ? Colors.grey.withOpacity(0.2) : null,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: _isLoginDisabled
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: accent.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _isLoginDisabled ? null : _handleLogin,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLoginDisabled ? Icons.lock_clock_rounded : Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLoginDisabled ? "Terkunci (10 detik)" : "Masuk",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Footer keamanan
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user_rounded, size: 14, color: Colors.green[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Koneksi aman & terenkripsi",
                                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                  
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    const accent = Color(0xFFF59E0B);
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: accent.withOpacity(0.7), size: 20),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
