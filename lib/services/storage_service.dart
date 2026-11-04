import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _box = GetStorage();

  static String? get token => _box.read('token');
  static set token(String? v) => _box.write('token', v);

  static String? get refreshToken => _box.read('refreshToken');
  static set refreshToken(String? v) => _box.write('refreshToken', v);

  static int? get userId => _box.read('userId');
  static set userId(int? v) => _box.write('userId', v);

  static String? get themeMode => _box.read('themeMode');
  static set themeMode(String? v) => _box.write('themeMode', v);

  static double get fontSize => _box.read('fontSize') ?? 14.0;
  static set fontSize(double v) => _box.write('fontSize', v);

  static void clearAuth() {
    _box.remove('token');
    _box.remove('refreshToken');
    _box.remove('userId');
  }

  static bool get isLoggedIn => token != null && token!.isNotEmpty;
}
