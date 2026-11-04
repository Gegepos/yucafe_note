import 'package:get/get.dart';
import '../models/coffee_bean.dart';
import '../services/bean_service.dart';
import '../utils/error_utils.dart';

class BeanController extends GetxController {
  static const int pageSize = 20;

  final BeanService _service = BeanService();
  final beans = <CoffeeBean>[].obs;

  /// 首屏 / 下拉刷新时的加载状态。
  final isLoading = false.obs;

  /// 上拉加载更多时的加载状态（与 isLoading 分开，避免骨架屏闪一下）。
  final isLoadingMore = false.obs;

  final currentPage = 1.obs;
  final totalCount = 0.obs;
  final selectedBean = Rxn<CoffeeBean>();
  final keyword = ''.obs;
  final hasMore = true.obs;

  Future<void> fetchBeans({bool refresh = false}) async {
    // 已在加载中就不重复发请求（滚动监听会高频触发）。
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
    } else if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    if (refresh) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final data = await _service.listBeans(
        page: currentPage.value,
        size: pageSize,
        keyword: keyword.value.isNotEmpty ? keyword.value : null,
      );
      final records = (data['records'] as List).map((e) => CoffeeBean.fromJson(e)).toList();

      if (refresh) {
        beans.value = records;
      } else if (records.isNotEmpty) {
        beans.addAll(records);
      }

      final total = (data['total'] as num?)?.toInt() ?? 0;
      totalCount.value = total;
      // records 为空说明已经到底；否则用 total 判断，兼容 total 缺失的老接口。
      hasMore.value = records.isNotEmpty && (total == 0 || beans.length < total);
      if (records.isNotEmpty) currentPage.value++;
    } catch (_) {
      // 加载失败保持原状，下次滚动还能重试。
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<CoffeeBean?> fetchDetail(int id) async {
    try {
      final data = await _service.getDetail(id);
      selectedBean.value = CoffeeBean.fromJson(data);
      return selectedBean.value;
    } catch (_) { return null; }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try { await _service.create(data); fetchBeans(refresh: true); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  Future<bool> updateBean(int id, Map<String, dynamic> data) async {
    try { await _service.update(id, data); fetchBeans(refresh: true); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      beans.removeWhere((b) => b.id == id);
      await fetchBeans(refresh: true);
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    }
  }

  Future<bool> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return false;
    try {
      await _service.batchDelete(ids);
      beans.removeWhere((b) => ids.contains(b.id));
      await fetchBeans(refresh: true);
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>> checkExists() async {
    try { return await _service.checkExists(); }
    catch (_) { return {'exists': false, 'count': 0}; }
  }
}
