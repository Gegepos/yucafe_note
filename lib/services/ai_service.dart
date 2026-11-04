import 'api_client.dart';
import '../utils/error_utils.dart';

class AiService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> _handle(Future<dynamic> future) async {
    final res = await future;
    return ErrorUtils.data(res.data);
  }

  Future<void> _handleVoid(Future<dynamic> future) async {
    final res = await future;
    ErrorUtils.ensureOk(res.data);
  }

  /// 生成冲煮建议；后端在模型不可用时会自动回退到规则模板。
  Future<Map<String, dynamic>> recommend({
    required int beanId,
    String? device,
    String? preference,
  }) {
    return _handle(_dio.post('/ai/recommend', data: {
      'beanId': beanId,
      if (device != null && device.isNotEmpty) 'device': device,
      if (preference != null && preference.isNotEmpty) 'preference': preference,
    }));
  }

  Future<List<dynamic>> history(int beanId, {int limit = 10}) async {
    final res = await _dio.get('/ai/history', queryParameters: {
      'beanId': beanId,
      'limit': limit,
    });
    final body = res.data;
    if (body is! Map) throw Exception('网络异常，请稍后重试');
    return ErrorUtils.list(Map<String, dynamic>.from(body));
  }

  /// 个人 DeepSeek 接入状态
  Future<Map<String, dynamic>> getSetting() => _handle(_dio.get('/ai/setting'));

  Future<Map<String, dynamic>> saveSetting(String apiKey, {String? model}) =>
      _handle(_dio.put('/ai/setting', data: {
        'apiKey': apiKey,
        if (model != null && model.isNotEmpty) 'model': model,
      }));

  Future<void> clearSetting() => _handleVoid(_dio.delete('/ai/setting'));

  /// 最近 N 天 token 用量
  Future<Map<String, dynamic>> usage({int days = 14}) =>
      _handle(_dio.get('/ai/usage', queryParameters: {'days': days}));
}
