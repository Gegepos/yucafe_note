import 'api_client.dart';
import 'storage_service.dart';
import '../utils/error_utils.dart';

class AuthService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> _handle(Future<dynamic> future) async {
    final res = await future;
    return ErrorUtils.data(res.data);
  }

  Future<Map<String, dynamic>> register({
    required String username, required String password,
    required String nickname, required String confirmPassword,
  }) async {
    final data = await _handle(_dio.post('/auth/register', data: {
      'username': username, 'password': password,
      'nickname': nickname, 'confirmPassword': confirmPassword,
    }));
    _saveLoginData(data);
    return data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await _handle(_dio.post('/auth/login', data: {
      'username': username, 'password': password,
    }));
    _saveLoginData(data);
    return data;
  }

  Future<Map<String, dynamic>> refresh() async {
    final refreshToken = StorageService.refreshToken;
    final data = await _handle(_dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    }));
    _saveLoginData(data);
    return data;
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    StorageService.clearAuth();
  }

  void _saveLoginData(Map<String, dynamic> data) {
    StorageService.token = data['token'];
    StorageService.refreshToken = data['refreshToken'];
    StorageService.userId = data['userId'];
  }
}
