import 'package:flutter/material.dart';
import 'package:logbook_app_069/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

 
  final List<Color> bgColors = [
    const Color(0xFFFFFBF0), 
    const Color(0xFFFFFDE7), 
    const Color(0xFFFFF8E1), 
  ];

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Jadikan Setiap Catatan Berarti",
      "description":
          "Catat, pantau, dan kelola logbook aktivitas harianmu dengan cara yang lebih cerdas dan menyenangkan.",
      "image": "assets/images/onboarding1.png",
      "badge": "Produktivitas",
    },
    {
      "title": "Data Anda, Privasi Anda",
      "description":
          "Semua riwayat dan hitungan tersimpan aman di perangkat Anda. Tidak ada yang bisa mengakses data Anda selain Anda.",
      "image": "assets/images/onboarding2.png",
      "badge": "Keamanan",
    },
    {
      "title": "Raih Target Lebih Cepat",
      "description":
          "Gunakan fitur langkah kustom untuk menyesuaikan progresmu. Setiap pencapaian tersimpan dan bisa dilihat kapan saja!",
      "image": "assets/images/onboarding3.png",
      "badge": "Pencapaian",
    },
  ];

  void nextStep() {
    if (step >= 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      setState(() {
        step++;
      });
    }
  }

  void prevStep() {
    if (step > 1) {
      setState(() {
        step--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = onboardingData[step - 1];
    final currentBg = bgColors[step - 1];

    return Scaffold(
      backgroundColor: currentBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button di kanan atas
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: step < 3
                    ? TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                          );
                        },
                        child: const Text(
                          "Lewati",
                          style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                        ),
                      )
                    : const SizedBox(height: 40),
              ),
            ),

            // Badge label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentData["badge"]!,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Gambar Onboarding
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Image.asset(
                  currentData["image"]!,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Konten bawah — putih rounded
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Indicator
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = step == index + 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE5E7EB),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Judul
                  Text(
                    currentData["title"]!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Deskripsi
                  Text(
                    currentData["description"]!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tombol navigasi
                  Row(
                    children: [
                      if (step > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: OutlinedButton(
                            onPressed: prevStep,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(56, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: Color(0xFF374151)),
                          ),
                        ),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: nextStep,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  step == 3 ? "Mulai Sekarang!" : "Selanjutnya",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
