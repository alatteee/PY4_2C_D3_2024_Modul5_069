import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_069/features/logbook/log_controller.dart';
import 'package:logbook_app_069/features/logbook/log_editor_page.dart';
import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';
import 'package:logbook_app_069/services/access_control_service.dart';

const kPrimary = Color(0xFFF59E0B);
const kPrimaryDark = Color(0xFFD97706);
const kPrimaryLight = Color(0xFFFFFBEB);
const kTextDark = Color(0xFF1F2937);
const kTextGrey = Color(0xFF6B7280);
// Border radius constants
const _kInputRadius = 12.0;
const _kCardRadius = 16.0;
const _kDialogRadius = 20.0;
const _kButtonRadius = 10.0;

// Category items untuk dropdown
const _categoryItems = [
  {'name': 'Pekerjaan', 'icon': Icons.work_rounded, 'color': Colors.blue},
  {'name': 'Pribadi', 'icon': Icons.person_rounded, 'color': Colors.green},
  {'name': 'Urgent', 'icon': Icons.priority_high_rounded, 'color': Colors.red},
];

// Helper: Category lookup from _categoryItems
Map<String, dynamic> _catLookup(String name) =>
    _categoryItems.firstWhere((c) => c['name'] == name, orElse: () => _categoryItems[1]);

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late LogController _controller;
  late Future<List<LogModel>> _logsFuture;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  static const Duration _kMinLoadingDebug = Duration(seconds: 2);

  String _formatIndonesianTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.isNegative) {
      return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
    }

    if (diff.inSeconds < 45) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';

    return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
  }

  String _friendlyCloudError(Object? error) {
    final raw = (error ?? '').toString();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('no address associated') ||
        lower.contains('connection reset')) {
      return 'Koneksi internet terputus atau tidak stabil. Aktifkan internet lalu coba lagi.';
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Koneksi ke server terlalu lama (timeout). Coba lagi atau ganti jaringan.';
    }

    return 'Tidak bisa terhubung ke Cloud saat ini. Coba lagi beberapa saat.';
  }

  Future<void> _refreshLogsAsync() async {
    _refreshLogs();
    try {
      await _logsFuture;
    } catch (_) {
      // Error state ditangani oleh FutureBuilder
    }
  }

  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    final offline = initial == ConnectivityResult.none;
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nowOffline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && nowOffline != _isOffline) {
        setState(() => _isOffline = nowOffline);
        if (!nowOffline) {
          _refreshLogs();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final currentUser = _currentUser();
    _controller = LogController(
      userId: currentUser['uid']!,
      userRole: currentUser['role']!,
      teamId: currentUser['teamId']!,
    );

    // Future-based fetch untuk menangani latensi Cloud
    _logsFuture = _fetchLogs();

    // Pantau konektivitas agar offline warning muncul walau user masih di layar list
    _initConnectivity();
  }

  Future<List<LogModel>> _fetchLogs() async {
    final stopwatch = Stopwatch()..start();

    await LogHelper.writeLog(
      "UI: Memulai fetch data untuk team ${_controller.teamId} dari Cloud...",
      source: "log_view.dart",
      level: 2,
    );

    try {
      final logs = await _controller.loadLogs();

      if (_isOffline) {
        setState(() => _isOffline = false);
      }

      await LogHelper.writeLog(
        "UI: Fetch selesai (${logs.length} data)",
        source: "log_view.dart",
        level: 2,
      );

      return logs;
    } catch (e) {
      if (!_isOffline) {
        setState(() => _isOffline = true);
      }
      await LogHelper.writeLog(
        "UI: Fetch gagal ($e)",
        source: "log_view.dart",
        level: 1,
      );
      rethrow;
    } finally {
      
      if (kDebugMode) {
        final remaining = _kMinLoadingDebug - stopwatch.elapsed;
        if (!remaining.isNegative) {
          await Future<void>.delayed(remaining);
        }
      }
    }
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return "Selamat Pagi ☀️";
    if (hour < 15) return "Selamat Siang 🌤️";
    if (hour < 18) return "Selamat Sore 🌅";
    return "Selamat Malam 🌙";
  }

  // Helper: Centered status popup (auto-dismiss)
  void _showStatusPopup(String message, {IconData icon = Icons.check_circle_rounded, Color? color}) {
    final c = color ?? Colors.green[600]!;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Dialog(
          backgroundColor: kPrimaryLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kDialogRadius)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: c, size: 36),
                ),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper: Confirmation dialog (returns true if confirmed)
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Ya',
    Color? confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPrimaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kDialogRadius)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kTextGrey,
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Map<String, String> _currentUser() {
    final normalizedUsername = widget.username.toLowerCase();
    final role = normalizedUsername == 'admin' ? 'Ketua' : 'Anggota';
    final teamId = switch (normalizedUsername) {
      'admin' || 'user1' => 'MEKTRA_KLP_01',
      'user2' => 'MEKTRA_KLP_02',
      _ => 'MEKTRA_KLP_01',
    };

    return {
      'uid': widget.username,
      'username': widget.username,
      'role': role,
      'teamId': teamId,
    };
  }

  Future<void> _goToEditor({LogModel? log, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: _currentUser(),
        ),
      ),
    );

    _refreshLogs();
  }

  void _showDeleteConfirm(int index) async {
    if (await _showConfirmDialog(
      title: "Hapus Catatan?",
      content: "Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak bisa dibatalkan.",
      confirmText: "Ya, Hapus",
      confirmColor: Colors.red[400],
    )) {
      await _controller.removeLog(index);
      _refreshLogs();
      _showStatusPopup("Catatan berhasil dihapus!", icon: Icons.delete_rounded, color: Colors.orange[700]);
    }
  }

  void _showLogoutConfirm() async {
    if (await _showConfirmDialog(
      title: "Konfirmasi Logout",
      content: "Apakah Anda yakin ingin keluar? Sesi Anda akan diakhiri.",
      confirmText: "Ya, Keluar",
      confirmColor: Colors.red[400],
    )) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingView()),
          (route) => false,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 18, color: kPrimaryDark),
            ),
            const SizedBox(width: 8),
            const Text("Logbook", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              ),
              onPressed: _showLogoutConfirm,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: _isOffline ? 96 : 0),
            child: Column(
              children: [
          // ===== HEADER GOLD PANEL =====
          ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (context, logs, _) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTimeGreeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${logs.length} catatan tersimpan",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_kCardRadius),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  _controller.searchLog(value);
                },
                decoration: InputDecoration(
                  hintText: "Cari catatan...",
                  hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: kTextGrey, size: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const Expanded(
            child: _LogListSection(),
          ),
              ],
            ),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildOfflineBanner(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToEditor,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
        elevation: 4,
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Offline Mode',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tidak ada koneksi internet. Aktifkan data lalu tarik untuk refresh.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _refreshLogsAsync,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogListSection extends StatelessWidget {
  const _LogListSection();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CounterViewState>()!;

    return FutureBuilder<List<LogModel>>(
      future: state._logsFuture,
      builder: (context, snapshot) {
        // 1. Loading State (latensi Cloud)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: kPrimary),
                SizedBox(height: 16),
                Text("Mengambil data dari MongoDB Atlas..."),
              ],
            ),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          final message = state._friendlyCloudError(snapshot.error);
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: state._refreshLogsAsync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 120),
                Column(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    const Text(
                      'Offline Mode Warning',
                      style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextGrey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: state._refreshLogs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarik ke bawah untuk refresh.',
                      style: TextStyle(color: kTextGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // 3. Data kosong
        // Gunakan state controller sebagai sumber UI utama agar konsisten
        // dengan update lokal dari Hive/offline-first.
        final currentStoredLogs = state._controller.logsNotifier.value;
        if (currentStoredLogs.isEmpty) {
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: state._refreshLogsAsync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 140),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Data Kosong"),
                      const SizedBox(height: 4),
                      Text("Belum ada catatan di Cloud.", style: TextStyle(color: kTextGrey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => state._goToEditor(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text("Buat Catatan Pertama"),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tarik ke bawah untuk refresh.',
                        style: TextStyle(color: kTextGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 4. Jika data sudah ada, render list seperti biasa
        return ValueListenableBuilder<List<LogModel>>(
          valueListenable: state._controller.filteredLogs,
          builder: (context, currentLogs, child) {
            return RefreshIndicator(
              color: kPrimary,
              onRefresh: state._refreshLogsAsync,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: currentLogs.length,
                itemBuilder: (context, index) {
                  final log = currentLogs[index];
            final cat = _catLookup(log.category);
            final color = cat['color'] as Color;
            final actualIndex = state._controller.logsNotifier.value.indexWhere(
              (l) => (log.id != null && l.id == log.id) || (l.date == log.date),
            );
            final currentUserId = state.widget.username;
            final currentRole = currentUserId.toLowerCase() == 'admin'
                ? 'Ketua'
                : 'Anggota';
            final isOwner = log.authorId == currentUserId;
            final canEdit = AccessControlService.canPerform(
              currentRole,
              AccessControlService.actionUpdate,
              isOwner: isOwner,
            );
            final canDelete = AccessControlService.canPerform(
              currentRole,
              AccessControlService.actionDelete,
              isOwner: isOwner,
            );
            return Dismissible(
              key: Key(
                log.id?.toHexString() ?? log.date.toIso8601String(),
              ),
              direction: canDelete
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                  ),
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text("Hapus", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              confirmDismiss: (_) => canDelete
                  ? state._showConfirmDialog(
                      title: "Hapus Catatan?",
                      content:
                          "Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak bisa dibatalkan.",
                      confirmText: "Ya, Hapus",
                      confirmColor: Colors.red[400],
                    )
                  : Future.value(false),
              onDismissed: (direction) async {
                if (canDelete && actualIndex != -1) {
                  await state._controller.removeLog(actualIndex);
                  state._refreshLogs();
                  state._showStatusPopup(
                    "Catatan berhasil dihapus!",
                    icon: Icons.delete_rounded,
                    color: Colors.orange[700],
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                    onTap: canEdit
                        ? () => state._goToEditor(
                              log: log,
                              index: actualIndex != -1 ? actualIndex : index,
                            )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.15),
                                  color.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(_kInputRadius),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + Category Badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: kTextDark,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Indikator Sinkronisasi
                                    Icon(
                                      log.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                      size: 16,
                                      color: log.isSynced ? Colors.green[600] : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        log.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Description
                                Text(
                                  log.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kTextGrey,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state._formatIndonesianTimestamp(log.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kTextGrey.withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Popup Menu dengan Gatekeeper (RBAC)
                          Builder(
                            builder: (context) {
                              // Jika tidak punya izin apapun, sembunyikan menu
                              if (!canEdit && !canDelete) {
                                return const SizedBox.shrink();
                              }

                              return PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: kTextGrey, size: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_kInputRadius),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit' && canEdit) {
                                    state._goToEditor(
                                      log: log,
                                      index: actualIndex != -1
                                          ? actualIndex
                                          : index,
                                    );
                                  } else if (value == 'delete' && canDelete) {
                                    if (actualIndex != -1) {
                                      state._showDeleteConfirm(actualIndex);
                                    }
                                  }
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];

                                  if (canEdit) {
                                    items.add(
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded,
                                                size: 18,
                                                color: Colors.blue[600]),
                                            const SizedBox(width: 12),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (canDelete) {
                                    items.add(
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded,
                                                size: 18,
                                                color: Colors.red[600]),
                                            const SizedBox(width: 12),
                                            const Text('Hapus'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return items;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
