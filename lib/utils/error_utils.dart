import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_keys.dart';

class ErrorUtils {
  static String _extract(dynamic e) {
    if (e is Map) return '${e['message'] ?? '操作失败'}';
    if (e is String) return e;
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
  }

  static void showError(dynamic e) => _show(_extract(e), success: false);

  static void showSuccess(String msg) => _show(msg, success: true);

  /// 提示条走 App 级 ScaffoldMessenger：跨页面存活，且不依赖 GetX overlay。
  /// 万一拿不到 messenger（极早期调用），退回 GetX 的 snackbar。
  static void _show(String msg, {required bool success}) {
    final messenger = appMessengerKey.currentState;
    if (messenger == null) {
      Get.snackbar(
        success ? '成功' : '错误',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: success ? 2 : 3),
      );
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: success ? 2 : 3),
      ),
    );
  }

  static bool isOk(Map<String, dynamic> res) => res['code'] == 200;

  /// 只校验业务码，不要求 data 非空。
  /// 用于 update / delete 这类后端返回 Result.success()（data 为 null）的接口。
  static void ensureOk(dynamic res) {
    if (res is! Map || res['code'] != 200) {
      throw Exception(res is Map ? (res['message'] ?? '请求失败') : '网络异常，请稍后重试');
    }
  }

  /// 取对象型 data。没有 data 视为异常。
  static Map<String, dynamic> data(Map<String, dynamic> res) {
    if (!isOk(res)) throw Exception(res['message'] ?? '请求失败');
    final d = res['data'];
    if (d == null) throw Exception('数据为空');
    return d is Map<String, dynamic> ? d : <String, dynamic>{};
  }

  /// 取数组型 data。后端部分接口（如 /dashboard/favorites）直接返回 List。
  static List<dynamic> list(Map<String, dynamic> res) {
    if (!isOk(res)) throw Exception(res['message'] ?? '请求失败');
    final d = res['data'];
    return d is List ? d : const <dynamic>[];
  }
}
