import 'package:get/get.dart';
import '../models/coffee_note.dart';
import '../services/note_service.dart';
import '../utils/error_utils.dart';
import 'dashboard_controller.dart';

class NoteController extends GetxController {
  static const int pageSize = 20;

  final NoteService _service = NoteService();
  final notes = <CoffeeNote>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final currentPage = 1.obs;
  final totalCount = 0.obs;
  final selectedNote = Rxn<CoffeeNote>();
  final filterBeanId = Rxn<int>();
  final hasMore = true.obs;

  Future<void> fetchNotes({bool refresh = false}) async {
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
      final data = await _service.listNotes(
        page: currentPage.value,
        size: pageSize,
        beanId: filterBeanId.value,
      );
      final records = (data['records'] as List).map((e) => CoffeeNote.fromJson(e)).toList();

      if (refresh) {
        notes.value = records;
      } else if (records.isNotEmpty) {
        notes.addAll(records);
      }

      final total = (data['total'] as num?)?.toInt() ?? 0;
      totalCount.value = total;
      hasMore.value = records.isNotEmpty && (total == 0 || notes.length < total);
      if (records.isNotEmpty) currentPage.value++;
    } catch (_) {
      // 加载失败保持原状，下次滚动还能重试。
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<CoffeeNote> fetchDetail(int id) async {
    final data = await _service.getDetail(id);
    selectedNote.value = CoffeeNote.fromJson(data);
    return selectedNote.value!;
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try { await _service.create(data); fetchNotes(refresh: true); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  Future<bool> updateNote(int id, Map<String, dynamic> data) async {
    try { await _service.update(id, data); fetchNotes(refresh: true); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  /// 去冲煮：成功后刷新笔记列表与控制中枢（本周冲煮/总存量/距上次冲煮）。
  Future<Map<String, dynamic>?> brew(int id) async {
    try {
      final data = await _service.brew(id);
      final times = (data['times'] as num?)?.toInt() ?? 0;
      final beanName = data['beanName'] ?? '咖啡豆';
      final before = _num(data['stockBefore']);
      final after = _num(data['stockAfter']);
      final shortage = data['shortage'] == true;
      final tail = shortage
          ? '；存量不足，已扣减至 ${_fmt(after)}g'
          : '（${_fmt(before)} → ${_fmt(after)}g）';
      ErrorUtils.showSuccess('已记录冲煮：$beanName 第 $times 次$tail');
      await fetchNotes(refresh: true);
      await Get.find<DashboardController>().fetchAll();
      return data;
    } catch (e) {
      ErrorUtils.showError(e);
      return null;
    }
  }

  static double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      notes.removeWhere((n) => n.id == id);
      await fetchNotes(refresh: true);
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    }
  }
}
