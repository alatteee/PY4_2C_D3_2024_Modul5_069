// login_controller.dart
class LoginController {
  // Database sederhana menggunakan Map untuk multiple users
  final Map<String, String> _users = {
    'admin': '123',
    'user1': 'pass1',
    'user2': 'pass2',
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    // Cek apakah username ada di database dan passwordnya cocok
    if (_users.containsKey(username) && _users[username] == password) {
      return true;
    }
    return false;
  }
}
