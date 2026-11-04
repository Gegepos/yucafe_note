import 'api_client.dart';
import '../utils/error_utils.dart';

class NoteService {
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

  Future<Map<String, dynamic>> listNotes({int page = 1, int size = 20, int? beanId}) async {
    return _handle(_dio.get('/notes', queryParameters: {
      'page': page, 'size': size, if (beanId != null) 'beanId': beanId,
    }));
  }

  Future<Map<String, dynamic>> getDetail(int id) => _handle(_dio.get('/notes/$id'));
  Future<int> create(Map<String, dynamic> data) async {
    final d = await _handle(_dio.post('/notes', data: data));
    return d['id'];
  }
  Future<void> update(int id, Map<String, dynamic> data) => _handleVoid(_dio.put('/notes/$id', data: data));
  Future<void> delete(int id) => _handleVoid(_dio.delete('/notes/$id'));

  /// 去冲煮：冲煮次数 +1，咖啡豆存量按本次豆量扣减
  Future<Map<String, dynamic>> brew(int id) => _handle(_dio.post('/notes/$id/brew'));
}
