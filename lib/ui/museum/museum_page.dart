import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bean_controller.dart';
import '../../app/routes.dart';
import '../../models/coffee_bean.dart';
import '../../utils/error_utils.dart';
import '../widgets/bean_card.dart';
import '../widgets/loader.dart';

class MuseumPage extends StatefulWidget {
  const MuseumPage({super.key});

  @override
  State<MuseumPage> createState() => _MuseumPageState();
}

class _MuseumPageState extends State<MuseumPage> {
  final BeanController ctrl = Get.find<BeanController>();
  final ScrollController _scroll = ScrollController();
  final Set<int> _selected = <int>{};
  bool _selecting = false;

  /// 已展开的卡片（展开后才去下载图片）。
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    ctrl.fetchBeans(refresh: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// 滚动到距底部 300px 时预加载下一页。
  /// 重复触发是安全的：fetchBeans 内部有 hasMore / isLoadingMore 守卫。
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ctrl.fetchBeans();
    }
  }

  void _toggleExpand(int id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  void _enterSelecting(int id) {
    setState(() {
      _selecting = true;
      _selected.add(id);
    });
  }

  void _toggle(int id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _exitSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleSelectAll(List<CoffeeBean> beans) {
    setState(() {
      if (_selected.length == beans.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(beans.map((b) => b.id).whereType<int>());
      }
    });
  }

  Future<void> _openDetail(int id) async {
    final result = await Get.toNamed(AppRoutes.beanDetail, arguments: id);
    if (result == true) {
      ErrorUtils.showSuccess('删除成功');
      await ctrl.fetchBeans(refresh: true);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${ids.length} 个咖啡豆？\n关联的冲煮笔记也会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ctrl.deleteMany(ids);
    if (!mounted) return;
    if (!ok) return;
    _exitSelecting();
    ErrorUtils.showSuccess('已删除 ${ids.length} 个咖啡豆');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final beans = ctrl.beans;
      if (ctrl.isLoading.value && beans.isEmpty) {
        return const CardListSkeleton();
      }
      if (beans.isEmpty) {
        if (_selecting) {
          // 删光了就自动退出多选态，避免工具条悬空。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selecting) _exitSelecting();
          });
        }
        return RefreshIndicator(
          onRefresh: () => ctrl.fetchBeans(refresh: true),
          child: ListView(
            children: const [
              SizedBox(height: 120),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.coffee_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      '暂无咖啡豆',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '点击下方 + 新增',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          if (_selecting) _selectionBar(beans),
          Expanded(child: _list(beans)),
          if (_selecting) _deleteBar(),
        ],
      );
    });
  }

  Widget _selectionBar(List<CoffeeBean> beans) {
    final theme = Theme.of(context);
    final allSelected = _selected.length == beans.length;
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            '已选 ${_selected.length} / ${beans.length}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _toggleSelectAll(beans),
            child: Text(allSelected ? '取消全选' : '全选'),
          ),
          TextButton(onPressed: _exitSelecting, child: const Text('完成')),
        ],
      ),
    );
  }

  Widget _deleteBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: Text(
              _selected.isEmpty ? '请选择要删除的咖啡豆' : '删除 (${_selected.length})',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<CoffeeBean> beans) {
    return RefreshIndicator(
      onRefresh: () => ctrl.fetchBeans(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: beans.length + 1,
        itemBuilder: (context, index) {
          if (index == beans.length) return _footer(beans.length);
          final bean = beans[index];
          final beanId = bean.id;
          if (beanId == null) {
            return BeanCard(bean: bean, onTap: () {});
          }
          return BeanCard(
            bean: bean,
            selecting: _selecting,
            selected: _selected.contains(beanId),
            expanded: _expanded.contains(beanId),
            onLongPress: () => _enterSelecting(beanId),
            onTap: () => _selecting ? _toggle(beanId) : _openDetail(beanId),
            onToggleExpand: () => _toggleExpand(beanId),
          );
        },
      ),
    );
  }

  /// 列表底部：加载中 / 到底了 / 什么都没（不足一页时不留空白）。
  ///
  /// 单独包一层 Obx：`isLoadingMore` / `hasMore` 变化时只重建这一格，
  /// 不会带着整个列表一起重建。
  Widget _footer(int loaded) {
    return Obx(() {
      if (ctrl.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (!ctrl.hasMore.value && loaded >= BeanController.pageSize) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '— 已经到底了 —',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        );
      }
      return const SizedBox(height: 8);
    });
  }
}
