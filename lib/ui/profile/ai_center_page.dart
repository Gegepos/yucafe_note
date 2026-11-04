import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ai_controller.dart';
import '../../app/routes.dart';

/// AI 管理：两栏 —— DeepSeek 接入 / Token 用量。
class AiCenterPage extends StatefulWidget {
  const AiCenterPage({super.key});

  @override
  State<AiCenterPage> createState() => _AiCenterPageState();
}

class _AiCenterPageState extends State<AiCenterPage> {
  final AiController _ctrl = Get.find<AiController>();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await _ctrl.loadSetting();
    await _ctrl.loadUsage(days: 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 管理')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('智能冲煮'),
            const SizedBox(height: 8),
            Obx(() {
              final setting = _ctrl.setting.value;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.key_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: const Text('DeepSeek 接入'),
                  subtitle: Text(
                    setting?.statusText ?? '读取中…',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openKeySheet,
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final usage = _ctrl.usage.value;
              final summary = usage == null
                  ? '读取中…'
                  : '近 ${usage.days} 天 ${usage.totalTokens} tokens · ${usage.totalCalls} 次调用';
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(Icons.insights_outlined,
                        color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                  title: const Text('Token 用量'),
                  subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(AppRoutes.aiUsage),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(
              '说明：芋咖记不提供公共 Key，AI 推荐必须使用你自己的 DeepSeek API Key，'
              '产生的费用记在你自己的账户上。Key 会加密后保存在服务器，只有你能使用；'
              '未接入时「AI 推荐冲煮参数」会引导你回到这里。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      );

  Future<void> _openKeySheet() async {
    final current = _ctrl.setting.value;
    final textCtrl = TextEditingController();
    final busy = ValueNotifier<bool>(false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('接入你自己的 DeepSeek', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '密钥只保存在服务端，AES-GCM 加密后入库，接口只回传末 4 位。'
                '不接入则无法使用 AI 推荐。',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              if (current?.configured == true) ...[
                const SizedBox(height: 8),
                Text(
                  '当前：${current?.maskedKey}（${current?.updatedAt ?? '-'} 更新）',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: busy,
                builder: (ctx, loading, _) => Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final key = textCtrl.text.trim();
                                if (key.isEmpty) {
                                  Get.snackbar('提示', '请先填写 API Key');
                                  return;
                                }
                                if (!key.startsWith('sk-')) {
                                  Get.snackbar('提示', 'Key 应以 sk- 开头');
                                  return;
                                }
                                busy.value = true;
                                final navigator = Navigator.of(ctx);
                                final ok = await _ctrl.saveKey(key);
                                busy.value = false;
                                if (ok && navigator.canPop()) navigator.pop();
                              },
                        child: loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('保存'),
                      ),
                    ),
                    if (current?.configured == true) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  busy.value = true;
                                  final navigator = Navigator.of(ctx);
                                  final ok = await _ctrl.clearKey();
                                  busy.value = false;
                                  if (ok && navigator.canPop()) navigator.pop();
                                },
                          child: const Text('清除'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    textCtrl.dispose();
    busy.dispose();
  }
}
