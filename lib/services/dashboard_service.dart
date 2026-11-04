import 'api_client.dart';
import '../utils/error_utils.dart';

class DashboardService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> _handle(Future<dynamic> future) async {
    final res = await future;
    return ErrorUtils.data(res.data);
  }

  Future<Map<String, dynamic>> getSummary() => _handle(_dio.get('/dashboard/summary'));

  /// 后端 /dashboard/favorites 直接返回数组，不能走 _handle（该方法只接受对象型 data）。
  Future<List<dynamic>> getFavorites() async {
    final res = await _dio.get('/dashboard/favorites');
    final body = res.data;
    if (body is! Map) throw Exception('网络异常，请稍后重试');
    return ErrorUtils.list(Map<String, dynamic>.from(body));
  }
}
