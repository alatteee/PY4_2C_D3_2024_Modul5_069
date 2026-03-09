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
		final permissions = _rolePermissions[role] ?? [];
		final hasBasicPermission = permissions.contains(action);

		// Logic khusus kepemilikan data (Owner-based RBAC)
		if (role == 'Anggota' &&
				(action == actionUpdate || action == actionDelete)) {
			return isOwner;
		}

		return hasBasicPermission;
	}
}

