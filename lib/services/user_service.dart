import 'package:dio/dio.dart' as dio;
import 'api_client.dart';
import '../utils/error_utils.dart';

class UserService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> _handle(Future<dynamic> future) async {
    final res = await future;
    return ErrorUtils.data(res.data);
  }

  Future<void> _handleVoid(Future<dynamic> future) async {
    final res = await future;
    if (!ErrorUtils.isOk(res.data)) return Future.error(res.data);
  }

  Future<Map<String, dynamic>> getProfile() => _handle(_dio.get('/user/profile'));
  Future<void> updateProfile(Map<String, dynamic> data) => _handleVoid(_dio.put('/user/profile', data: data));
  Future<void> changePassword(String oldPwd, String newPwd) => _handleVoid(_dio.put('/user/password', data: {'oldPassword': oldPwd, 'newPassword': newPwd}));
  Future<void> deleteAccount(String password) => _handleVoid(_dio.delete('/user/account', data: {'password': password}));

  Future<String> uploadAvatar(String filePath) async {
    final formData = dio.FormData.fromMap({'file': await dio.MultipartFile.fromFile(filePath)});
    final data = await _handle(_dio.post('/user/avatar', data: formData));
    return data['avatar'];
  }
}
