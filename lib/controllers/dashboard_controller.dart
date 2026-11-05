import 'package:get/get.dart';
import '../services/dashboard_service.dart';

class DashboardController extends GetxController {
  final DashboardService _service = DashboardService();
  final weeklyBrewCount = 0.obs;
  final totalStock = 0.0.obs;
  final daysSinceLastBrew = Rxn<int>();
  final beanCount = 0.obs;
  final favorites = [].obs;
  final isLoading = false.obs;

  /// 概览与常用笔记是两个互不依赖的接口，串行发会白等一个 RTT。
  ///
  /// 注意：`Future.wait` 默认 eagerError，任一失败会整体抛出并丢掉另一份
  /// 结果，所以这里先各自兜底成空值再合并 —— 单个接口挂了不影响另一块。
  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait<Object?>([
        _service.getSummary().catchError((_) => <String, dynamic>{}),
        _service.getFavorites().catchError((_) => <dynamic>[]),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      if (summary.isNotEmpty) {
        weeklyBrewCount.value = summary['weeklyBrewCount'] ?? 0;
        totalStock.value = (summary['totalStock'] ?? 0).toDouble();
        daysSinceLastBrew.value = summary['daysSinceLastBrew'];
        beanCount.value = summary['beanCount'] ?? 0;
      }

      final favs = results[1] as List<dynamic>;
      if (favs.isNotEmpty) {
        favorites.value = favs;
      }
    } catch (_) {
      // 已经分别兜底过，走到这里说明是意料之外的问题，静默即可。
    } finally {
      isLoading.value = false;
    }
  }
}
