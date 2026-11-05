import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/note_controller.dart';
import '../../controllers/bean_controller.dart';
import '../../app/routes.dart';
import '../../utils/error_utils.dart';
import '../widgets/loader.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final NoteController ctrl = Get.find<NoteController>();
  final BeanController beanCtrl = Get.find<BeanController>();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ctrl.fetchNotes(refresh: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// 滚动到距底部 300px 时预加载下一页（fetchNotes 内部有重复触发守卫）。
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ctrl.fetchNotes();
    }
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _openDetail(int id) async {
    final result = await Get.toNamed(AppRoutes.noteDetail, arguments: id);
    if (result == true) {
      ErrorUtils.showSuccess('删除成功');
      await ctrl.fetchNotes(refresh: true);
    }
  }

  /// 返回 false 表示让 Dismissible 回弹，列表由 Obx 依据 controller 的
  /// 数据重建，避免「滑掉但服务端没删成功」的错位。
  Future<bool> _confirmAndDelete(int id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定删除此笔记？'),
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
    if (confirm != true) return false;
    final ok = await ctrl.delete(id);
    if (ok && mounted) ErrorUtils.showSuccess('删除成功');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          if (beanCtrl.beans.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<int?>(
              key: ValueKey<int?>(ctrl.filterBeanId.value),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '按咖啡豆筛选',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              initialValue: ctrl.filterBeanId.value,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('全部')),
                ...beanCtrl.beans.map(
                  (b) => DropdownMenuItem<int?>(
                    value: b.id,
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                ctrl.filterBeanId.value = v;
                _scrollToTop();
                ctrl.fetchNotes(refresh: true);
              },
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value && ctrl.notes.isEmpty) {
              return const CardListSkeleton(count: 5);
            }
            if (ctrl.notes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      '暂无笔记',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }
            return RefreshIndicator(
              onRefresh: () => ctrl.fetchNotes(refresh: true),
              // 行高固定，用 SliverFixedExtentList 省掉逐项测量：
              // 滚动偏移可以直接按 index * extent 算出来，滚动条也更准。
              // footer 高度不同，所以单独放进 SliverToBoxAdapter。
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverFixedExtentList(
                    itemExtent: _rowExtent(context),
                    delegate: SliverChildBuilderDelegate(
                      childCount: ctrl.notes.length,
                      (context, index) {
                        final note = ctrl.notes[index];
                        final noteId = note.id;
                        return Dismissible(
                          key: Key('note_$noteId'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            if (noteId == null) return false;
                            await _confirmAndDelete(noteId);
                            return false;
                          },
                          child: ListTile(
                            leading: const Icon(Icons.coffee),
                            title: Text(note.beanName ?? '未知'),
                            subtitle: Text(
                              '${note.beanBrand ?? ""}  ${note.createTime ?? ""}',
                            ),
                            trailing: Text('${note.weight}g'),
                            onTap: noteId == null
                                ? null
                                : () => _openDetail(noteId),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: _footer(ctrl.notes.length)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 列表行高：ListTile 带副标题时基准 72，随系统字体缩放放大。
  double _rowExtent(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(72.0);
    return scaled < 72 ? 72 : scaled;
  }

  /// 列表底部：加载中 / 到底了。
  ///
  /// 单独包一层 Obx，避免分页状态变化时重建整个列表。
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
      if (!ctrl.hasMore.value && loaded >= NoteController.pageSize) {
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
