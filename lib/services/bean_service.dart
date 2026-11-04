import 'api_client.dart';
import '../utils/error_utils.dart';

class BeanService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> _handle(Future<dynamic> future) async {
    final res = await future;
    return ErrorUtils.data(res.data);
  }

  /// 无返回体的写接口：后端返回 Result.success()，data 为 null。
  Future<void> _handleVoid(Future<dynamic> future) async {
    final res = await future;
    ErrorUtils.ensureOk(res.data);
  }

  Future<Map<String, dynamic>> listBeans({int page = 1, int size = 20, String? keyword}) async {
    return _handle(_dio.get('/beans', queryParameters: {
      'page': page, 'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    }));
  }

  Future<Map<String, dynamic>> getDetail(int id) => _handle(_dio.get('/beans/$id'));
  Future<int> create(Map<String, dynamic> data) async {
    final d = await _handle(_dio.post('/beans', data: data));
    return d['id'];
  }
  Future<void> update(int id, Map<String, dynamic> data) => _handleVoid(_dio.put('/beans/$id', data: data));
  Future<void> delete(int id) => _handleVoid(_dio.delete('/beans/$id'));
  Future<void> batchDelete(List<int> ids) =>
      _handleVoid(_dio.post('/beans/batch-delete', data: {'ids': ids}));
  Future<Map<String, dynamic>> checkExists() => _handle(_dio.get('/beans/check-exists'));
}
