import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    // 后端所有业务结果都走 HTTP 200 + Result.code，这里保持放行，
    // 由 _isUnauthorized 统一判定 401（同时兼容旧后端的裸 401）。
    validateStatus: (status) => true,
  ));

  /// 刷新令牌专用实例：不挂拦截器，避免 /auth/refresh 自身再次触发刷新形成递归。
  static final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => true,
  ));

  /// 并发请求共用同一次刷新，避免多个 401 同时打刷新接口或互相踢下线。
  static Future<bool>? _refreshing;

  static const _retriedKey = 'retried_after_refresh';

  static void init() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        if (!_isUnauthorized(response) ||
            _isAuthPath(response.requestOptions.path) ||
            response.requestOptions.extra[_retriedKey] == true) {
          handler.next(response);
          return;
        }

        final ok = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
        if (!ok) {
          StorageService.clearAuth();
          Get.offAllNamed('/login');
          handler.next(response);
          return;
        }

        final options = response.requestOptions;
        options.extra[_retriedKey] = true;
        options.headers['Authorization'] = 'Bearer ${StorageService.token}';
        try {
          handler.resolve(await dio.fetch(options));
        } catch (_) {
          handler.next(response);
        }
      },
    ));
  }

  static bool _isUnauthorized(Response response) {
    if (response.statusCode == 401) return true;
    final data = response.data;
    return data is Map && data['code'] == 401;
  }

  static bool _isAuthPath(String path) =>
      path.contains('/auth/refresh') || path.contains('/auth/login');

  static Future<bool> _refresh() async {
    final refreshToken = StorageService.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final body = response.data;
      if (body is Map && body['code'] == 200 && body['data'] is Map) {
        final d = body['data'] as Map;
        StorageService.token = d['token'] as String?;
        StorageService.refreshToken = d['refreshToken'] as String?;
        final token = StorageService.token;
        return token != null && token.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }
}
