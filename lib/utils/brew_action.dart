import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/note_controller.dart';

/// 弹出「是否去冲煮？」，确认后就地执行：
/// 该笔记冲煮次数 +1、关联咖啡豆存量按本次豆量扣减、控制中枢数据刷新。
/// 返回 true 表示真的执行了冲煮（调用方可以据此刷新自己页面的数据）。
Future<bool> brewWithConfirm(int noteId) async {
  final confirm = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('去冲煮'),
      content: const Text('是否去冲煮？'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('确认')),
      ],
    ),
  );
  if (confirm != true) return false;

  final result = await Get.find<NoteController>().brew(noteId);
  return result != null;
}
