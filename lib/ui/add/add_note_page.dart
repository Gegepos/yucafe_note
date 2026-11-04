import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/note_controller.dart';
import '../../controllers/bean_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../app/routes.dart';
import '../../models/coffee_bean.dart';
import '../../models/coffee_note.dart';
import '../../utils/error_utils.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _devicesCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _grinderCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _recipeCtrl = TextEditingController();
  CoffeeBean? _selectedBean;
  List<CoffeeBean> _beans = [];

  /// 非空表示编辑模式（由笔记详情页通过 Get.arguments 传入）。
  CoffeeNote? _editing;
  bool get _isEdit => _editing != null;

  bool _submitting = false;
  bool _advising = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is CoffeeNote) {
      _editing = args;
      _prefill();
    }
    _checkBeans();
  }

  void _prefill() {
    final note = _editing;
    if (note == null) return;
    _weightCtrl.text = _numText(note.weight);
    _devicesCtrl.text = note.brewingDevices;
    _ratioCtrl.text = note.brewRatio;
    _tempCtrl.text = note.waterTemperature;
    _grinderCtrl.text = note.grinder;
    _sizeCtrl.text = note.grinderSize;
    _recipeCtrl.text = note.brewRecipe ?? '';
  }

  static String _numText(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String? _requiredValidator(String? v) =>
      (v ?? '').trim().isEmpty ? '必填' : null;

  Future<void> _checkBeans() async {
    final ctrl = Get.find<BeanController>();
    final result = await ctrl.checkExists();
    if (result['exists'] == false && !_isEdit) {
      if (mounted) {
        Get.dialog(AlertDialog(
          title: const Text('提示'),
          content: const Text('请先新增咖啡豆'),
          actions: [TextButton(onPressed: () => Get.back(), child: const Text('确定'))],
        )).then((_) => Get.back());
      }
      return;
    }
    await ctrl.fetchBeans(refresh: true);
    var beans = ctrl.beans.toList();
    final note = _editing;
    // 编辑模式下若该笔记的豆子不在第一页列表里，单独把它查回来，避免下拉框对不上。
    if (note != null && !beans.any((b) => b.id == note.beanId)) {
      final bean = await ctrl.fetchDetail(note.beanId);
      if (bean != null) beans = [bean, ...beans];
    }
    if (!mounted) return;
    CoffeeBean? selected;
    if (note != null) {
      for (final b in beans) {
        if (b.id == note.beanId) {
          selected = b;
          break;
        }
      }
    }
    setState(() {
      _beans = beans;
      _selectedBean = selected;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose(); _devicesCtrl.dispose(); _ratioCtrl.dispose();
    _tempCtrl.dispose(); _grinderCtrl.dispose(); _sizeCtrl.dispose();
    _recipeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      // 内联错误提示容易被忽略，再给一条明显的提示；停在原页面。
      ErrorUtils.showError('请填写带 * 的必填项');
      return;
    }
    if (_selectedBean == null) {
      ErrorUtils.showError('请选择咖啡豆');
      return;
    }
    final data = {
      'beanId': _selectedBean!.id,
      'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
      'brewingDevices': _devicesCtrl.text,
      'brewRatio': _ratioCtrl.text,
      'waterTemperature': _tempCtrl.text,
      'grinder': _grinderCtrl.text,
      'grinderSize': _sizeCtrl.text,
      'brewRecipe': _recipeCtrl.text,
    };
    final ctrl = Get.find<NoteController>();
    final editId = _editing?.id;
    setState(() => _submitting = true);
    bool ok;
    try {
      ok = _isEdit && editId != null
          ? await ctrl.updateNote(editId, data)
          : await ctrl.create(data);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!ok || !mounted) return;
    // 新增成功回传 'created'，由 MainPage 切到笔记 tab 并提示；
    // 编辑成功回传 true，由详情页提示。
    Get.back(result: _isEdit ? true : 'created');
  }

  /// 让 AI 依据这支配豆的档案与历史冲煮记录给一份参数，一键回填表单。
  Future<void> _aiRecommend() async {
    if (_advising) return;
    final bean = _selectedBean;
    if (bean == null) {
      ErrorUtils.showError('请先选择咖啡豆');
      return;
    }
    final beanId = bean.id;
    if (beanId == null) return;

    // 服务器不提供公共 Key：没接入就直接把用户带到「AI 管理」去配置
    final aiCtrl = Get.find<AiController>();
    if (aiCtrl.setting.value == null) {
      await aiCtrl.loadSetting();
      if (!mounted) return;
    }
    if (aiCtrl.setting.value?.configured != true) {
      ErrorUtils.showError('请先接入你自己的 DeepSeek API Key');
      await Get.toNamed(AppRoutes.aiCenter);
      if (!mounted) return;
      // 从「AI 管理」回来后如果已经接入了，就接着生成
      if (aiCtrl.setting.value?.configured != true) return;
    }

    setState(() => _advising = true);
    final advice = await aiCtrl.recommend(beanId);
    if (!mounted) return;
    setState(() => _advising = false);
    if (advice == null) return;
    setState(() {
      _weightCtrl.text = _numText(advice.weight);
      _devicesCtrl.text = advice.brewingDevices;
      _ratioCtrl.text = advice.brewRatio;
      _tempCtrl.text = advice.waterTemperature;
      _grinderCtrl.text = advice.grinder;
      _sizeCtrl.text = advice.grinderSize;
      _recipeCtrl.text = advice.brewRecipe ?? '';
    });
    ErrorUtils.showSuccess(advice.isAi ? 'AI 已生成冲煮参数' : '已用规则模板生成参数');
    Get.dialog(AlertDialog(
      title: Text(advice.isAi ? 'AI 推荐理由' : '规则推荐理由'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('粉量 ${_numText(advice.weight)}g　${advice.brewRatio}　${advice.waterTemperature}'),
            const SizedBox(height: 4),
            Text('${advice.grinder}　${advice.grinderSize}'),
            const SizedBox(height: 10),
            Text(advice.reason ?? '暂无说明'),
            if (advice.isAi) ...[
              const SizedBox(height: 10),
              Text(
                '模型：${advice.model ?? '-'}　tokens：${advice.completionTokens ?? '-'}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('知道了'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑笔记' : '新增笔记')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<CoffeeBean>(
                // 列表异步加载完成后需要重建内部 FormField，故用 key 跟随选中项。
                key: ValueKey<int>(_selectedBean?.id ?? -1),
                initialValue: _selectedBean,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '选择咖啡豆 *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: _beans.map((b) => DropdownMenuItem<CoffeeBean>(
                  value: b,
                  child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedBean = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_advising || _selectedBean == null) ? null : _aiRecommend,
                  icon: _advising
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_advising ? '生成中…' : 'AI 推荐冲煮参数'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _weightCtrl, decoration: const InputDecoration(labelText: '豆量 (g) *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return '必填';
                final weight = double.tryParse(text);
                if (weight == null || weight <= 0) return '请输入大于 0 的数字';
                return null;
              }),
              const SizedBox(height: 12),
              TextFormField(controller: _devicesCtrl, decoration: const InputDecoration(labelText: '冲煮器具 *', border: OutlineInputBorder()), validator: _requiredValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _ratioCtrl, decoration: const InputDecoration(labelText: '粉水比 *', border: OutlineInputBorder()), validator: _requiredValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _tempCtrl, decoration: const InputDecoration(labelText: '水温 *', border: OutlineInputBorder()), validator: _requiredValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _grinderCtrl, decoration: const InputDecoration(labelText: '磨豆机 *', border: OutlineInputBorder()), validator: _requiredValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _sizeCtrl, decoration: const InputDecoration(labelText: '研磨度 *', border: OutlineInputBorder()), validator: _requiredValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _recipeCtrl, decoration: const InputDecoration(labelText: '冲煮方案', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? '保存' : '提交'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
