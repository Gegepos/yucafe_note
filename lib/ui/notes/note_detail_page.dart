import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/note_controller.dart';
import '../../utils/brew_action.dart';
import '../../utils/error_utils.dart';
import '../widgets/loader.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key});
  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late final int _id = Get.arguments as int;
  late final NoteController _ctrl = Get.find<NoteController>();
  late Future<dynamic> _future;
  bool _brewing = false;

  @override
  void initState() {
    super.initState();
    _future = _ctrl.fetchDetail(_id);
  }

  /// 去冲煮：确认后次数 +1、扣减咖啡豆存量，成功后留在本页并刷新数据。
  Future<void> _brew() async {
    setState(() => _brewing = true);
    final ok = await brewWithConfirm(_id);
    if (!mounted) return;
    setState(() {
      _brewing = false;
      if (ok) _future = _ctrl.fetchDetail(_id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(body: AppLoading(text: '正在加载笔记…'));
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text('加载失败')));
        if (!snapshot.hasData)
          return const Scaffold(body: Center(child: Text('数据为空')));
        final note = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(note.beanName ?? '笔记详情'), actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () async {
              final changed = await Get.toNamed('/notes/add', arguments: note);
              if (changed == true && mounted) {
                ErrorUtils.showSuccess('保存成功');
                setState(() => _future = _ctrl.fetchDetail(_id));
              }
            }),
            IconButton(icon: const Icon(Icons.delete), onPressed: () async {
              final confirm = await Get.dialog<bool>(AlertDialog(
                title: const Text('删除确认'), content: const Text('确定删除此笔记？'),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
                  TextButton(onPressed: () => Get.back(result: true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ));
              if (confirm != true) return;
              final ok = await _ctrl.delete(_id);
              if (!ok) return;
              // 提示交给笔记列表页在返回后展示，避免 snackbar 随路由一起被销毁。
              Get.back(result: true);
            }),
          ]),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.beanName ?? '', style: Theme.of(context).textTheme.titleLarge),
                if (note.beanBrand != null) Text(note.beanBrand!, style: TextStyle(color: Colors.grey.shade600)),
                const Divider(height: 24),
                _row('豆量', '${note.weight}g'),
                _row('磨豆机', note.grinder),
                _row('研磨度', note.grinderSize),
                _row('冲煮器具', note.brewingDevices),
                _row('水温', note.waterTemperature),
                _row('粉水比', note.brewRatio),
                if (note.brewRecipe != null) ...[
                  const SizedBox(height: 12),
                  const Text('冲煮方案', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(note.brewRecipe!),
                ],
                const Spacer(),
                Row(
                  children: [
                    Text('冲煮次数: ${note.times}次', style: TextStyle(color: Colors.grey.shade500)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _brewing ? null : _brew,
                      icon: _brewing
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.local_cafe_outlined, size: 18),
                      label: Text(_brewing ? '记录中…' : '去冲煮'),
                    ),
                  ],
                ),
                if (note.createTime != null) Text('创建于: ${note.createTime}', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
    ]),
  );
}
