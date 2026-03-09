// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';
import 'package:logbook_app_069/services/mongo_service.dart';

Future<void> main() async {
  // Wajib untuk operasi async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load konfigurasi lingkungan dari file .env
    await dotenv.load(fileName: ".env");
    await LogHelper.writeLog(
      "ENV berhasil dimuat",
      source: "main.dart",
      level: 2,
    );

    // 1b. Locale Indonesia untuk formatting timestamp
    Intl.defaultLocale = 'id_ID';
    await initializeDateFormatting('id_ID', null);

    // 2. Inisialisasi Hive (Offline-First Local DB)
    await Hive.initFlutter();
    Hive.registerAdapter(LogModelAdapter());
    await Hive.openBox<LogModel>('offline_logs');

    // 3. Lakukan handshake dengan MongoDB Atlas
    await MongoService().connect();
    await LogHelper.writeLog(
      "Berhasil terhubung ke MongoDB",
      source: "main.dart",
      level: 2,
    );
  } catch (e) {
    // Kalau gagal, tetap jalankan aplikasi tapi log error-nya
    await LogHelper.writeLog(
      "Gagal inisialisasi MongoDB/ENV: $e",
      source: "main.dart",
      level: 1,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}
