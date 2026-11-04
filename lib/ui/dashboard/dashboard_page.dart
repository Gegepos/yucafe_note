import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../utils/brew_action.dart';
import '../widgets/note_card.dart';
import '../widgets/loader.dart';
import '../../models/coffee_note.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController ctrl = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    // 只在进入页面时拉一次，避免 Obx 重建时重复发请求。
    ctrl.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) return const AppLoading(text: '正在加载数据…');
      return RefreshIndicator(
        onRefresh: () => ctrl.fetchAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 3,
              shadowColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.brown.withValues(alpha: 0.15)
                  : Colors.black38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statCell('本周冲煮', '${ctrl.weeklyBrewCount.value}', '次'),
                        _divider(),
                        _statCell('咖啡豆数', '${ctrl.beanCount.value}', '支'),
                      ],
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Row(
                      children: [
                        _statCell('豆总存量', ctrl.totalStock.value >= 1000
                            ? '${(ctrl.totalStock.value / 1000).toStringAsFixed(1)}'
                            : ctrl.totalStock.value.toStringAsFixed(0),
                            ctrl.totalStock.value >= 1000 ? 'kg' : 'g'),
                        _divider(),
                        _statCell('距上次冲煮', ctrl.daysSinceLastBrew.value != null
                            ? '${ctrl.daysSinceLastBrew.value}' : '-',
                            ctrl.daysSinceLastBrew.value != null ? '天' : ''),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('常用笔记', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (ctrl.favorites.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('暂无笔记记录')))),
            ...ctrl.favorites.map((f) {
              final note = CoffeeNote.fromJson(f);
              final noteId = note.id;
              return NoteCard(
                note: note,
                onBrew: noteId == null ? null : () => brewWithConfirm(noteId),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _statCell(String label, String value, String unit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            RichText(
              textDirection: TextDirection.ltr,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return SizedBox(
      height: 40,
      child: VerticalDivider(width: 1, color: Colors.grey.shade300),
    );
  }
}
