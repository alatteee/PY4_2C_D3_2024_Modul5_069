import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
	// Mengambil daftar role dari .env (opsional), contoh: APP_ROLES=Ketua,Anggota,Asisten
	static List<String> get availableRoles =>
			dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

	static const String actionCreate = 'create';
	static const String actionRead = 'read';
	static const String actionUpdate = 'update';
	static const String actionDelete = 'delete';

	// Matrix perizinan yang fleksibel
	static final Map<String, List<String>> _rolePermissions = {
		'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
		'Anggota': [actionCreate, actionRead],
		'Asisten': [actionRead, actionUpdate],
	};

	/// Cek apakah [role] boleh melakukan [action].
	/// [isOwner] dipakai untuk aturan "hanya boleh edit/hapus milik sendiri".
	static bool canPerform(String role, String action, {bool isOwner = false}) {
		// Logika baru akan memanggil metode yang lebih spesifik.
		if (action == actionUpdate) {
			return canUpdate(role, isOwner: isOwner);
		}
		if (action == actionDelete) {
			return canDelete(role, isOwner: isOwner);
		}

		final permissions = _rolePermissions[role] ?? [];
		return permissions.contains(action);
	}

	/// Validasi izin untuk mengedit (update).
	static bool canUpdate(String role, {bool isOwner = false}) {
		// Ketua bisa edit semua.
		if (role == 'Ketua') return true;

		// Anggota hanya bisa edit miliknya sendiri.
		if (role == 'Anggota') return isOwner;

		// Role lain (misal: Asisten) bisa edit sesuai _rolePermissions.
		final permissions = _rolePermissions[role] ?? [];
		return permissions.contains(actionUpdate);
	}

	/// Validasi izin untuk menghapus (delete).
	static bool canDelete(String role, {bool isOwner = false}) {
		// Ketua bisa hapus semua.
		if (role == 'Ketua') return true;

		// Anggota hanya bisa hapus miliknya sendiri.
		if (role == 'Anggota') return isOwner;

		// Role lain tidak diizinkan menghapus secara default.
		return false;
	}
}

