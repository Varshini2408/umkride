import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyLogged  = 'isLoggedIn';
  static const String _keyUid     = 'uid';
  static const String _keyName    = 'name';
  static const String _keyEmail   = 'email';
  static const String _keyRole    = 'role';
  static const String _keyGender  = 'gender';

  static Future<void> saveSession({
    required String uid,
    required String name,
    required String email,
    required String role,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogged, true);
    await prefs.setString(_keyUid,    uid);
    await prefs.setString(_keyName,   name);
    await prefs.setString(_keyEmail,  email);
    await prefs.setString(_keyRole,   role);
    await prefs.setString(_keyGender, gender);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool>   isLoggedIn() async => (await SharedPreferences.getInstance()).getBool(_keyLogged) ?? false;
  static Future<String?> getUid()    async => (await SharedPreferences.getInstance()).getString(_keyUid);
  static Future<String?> getName()   async => (await SharedPreferences.getInstance()).getString(_keyName);
  static Future<String?> getEmail()  async => (await SharedPreferences.getInstance()).getString(_keyEmail);
  static Future<String?> getRole()   async => (await SharedPreferences.getInstance()).getString(_keyRole);
  static Future<String?> getGender() async => (await SharedPreferences.getInstance()).getString(_keyGender);
  static Future<bool>   isStudent()  async => (await getRole()) == 'STUDENT';
  static Future<bool>   isDriver()   async => (await getRole()) == 'DRIVER';
}
