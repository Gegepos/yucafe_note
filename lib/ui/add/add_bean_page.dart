import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../controllers/bean_controller.dart';
import '../../models/coffee_bean.dart';
import '../../services/api_client.dart';
import '../../utils/image_utils.dart';
import '../../utils/error_utils.dart';

class AddBeanPage extends StatefulWidget {
  const AddBeanPage({super.key});

  @override
  State<AddBeanPage> createState() => _AddBeanPageState();
}

class _AddBeanPageState extends State<AddBeanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _roastLevelCtrl = TextEditingController();
  final _processCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _remarkCtrl = TextEditingController();
  final _varietiesCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _productAreaCtrl = TextEditingController();
  final _estateCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _waterContentCtrl = TextEditingController();
  final _densityCtrl = TextEditingController();
  final _waterActivityCtrl = TextEditingController();
  final _agtronCtrl = TextEditingController();
  final _powderCtrl = TextEditingController();
  final _overallScoreCtrl = TextEditingController();
  final _flavorsCtrl = TextEditingController();
  final _cuppingScoreCtrl = TextEditingController();
  final _greenPriceCtrl = TextEditingController();
  final _roastedPriceCtrl = TextEditingController();

  DateTime? _roastDate;
  /// 编辑时咖啡豆原有的烘焙日期；用户没重新选择就沿用它。
  DateTime? _originalRoastDate;
  bool _isEdit = false;
  int? _editId;
  String? _imageUrl;
  bool _submitting = false;
  final _picker = ImagePicker();
  var _moreExpanded = false;

  @override
  void initState() {
    super.initState();
    final bean = Get.arguments as CoffeeBean?;
    if (bean != null) _loadBean(bean);
  }

  void _loadBean(CoffeeBean bean) {
    _isEdit = true;
    _editId = bean.id;
    _nameCtrl.text = bean.name;
    _brandCtrl.text = bean.brand ?? '';
    _countryCtrl.text = bean.country;
    _roastLevelCtrl.text = bean.roastLevel;
    _processCtrl.text = bean.process;
    _originalRoastDate = DateTime.tryParse(bean.roastDate);
    _roastDate = _originalRoastDate;
    _stockCtrl.text = bean.stock.toStringAsFixed(0);
    _remarkCtrl.text = bean.remark ?? '';
    _imageUrl = bean.image;
    _varietiesCtrl.text = bean.varieties ?? '';
    _altitudeCtrl.text = bean.altitude ?? '';
    _areaCtrl.text = bean.area ?? '';
    _productAreaCtrl.text = bean.productArea ?? '';
    _estateCtrl.text = bean.estate ?? '';
    _lotCtrl.text = bean.lot ?? '';
    _waterContentCtrl.text = bean.waterContent ?? '';
    _densityCtrl.text = bean.density ?? '';
    _waterActivityCtrl.text = bean.waterActivity ?? '';
    _agtronCtrl.text = bean.agtron?.toString() ?? '';
    _powderCtrl.text = bean.powder?.toString() ?? '';
    _overallScoreCtrl.text = bean.overallPersonalScores?.toString() ?? '';
    _flavorsCtrl.text = bean.flavors ?? '';
    _cuppingScoreCtrl.text = bean.cuppingScores?.toString() ?? '';
    _greenPriceCtrl.text = bean.greenPrice?.toString() ?? '';
    _roastedPriceCtrl.text = bean.roastedPrice?.toString() ?? '';
    // Auto-expand more info if any extra fields have data
    _moreExpanded = _hasExtraData();
  }

  bool _hasExtraData() {
    return _varietiesCtrl.text.isNotEmpty || _altitudeCtrl.text.isNotEmpty ||
        _areaCtrl.text.isNotEmpty || _productAreaCtrl.text.isNotEmpty ||
        _estateCtrl.text.isNotEmpty || _lotCtrl.text.isNotEmpty ||
        _waterContentCtrl.text.isNotEmpty || _densityCtrl.text.isNotEmpty ||
        _waterActivityCtrl.text.isNotEmpty || _agtronCtrl.text.isNotEmpty ||
        _powderCtrl.text.isNotEmpty || _overallScoreCtrl.text.isNotEmpty ||
        _flavorsCtrl.text.isNotEmpty || _cuppingScoreCtrl.text.isNotEmpty ||
        _greenPriceCtrl.text.isNotEmpty || _roastedPriceCtrl.text.isNotEmpty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose(); _countryCtrl.dispose();
    _roastLevelCtrl.dispose(); _processCtrl.dispose(); _stockCtrl.dispose();
    _remarkCtrl.dispose(); _varietiesCtrl.dispose(); _altitudeCtrl.dispose();
    _areaCtrl.dispose(); _productAreaCtrl.dispose(); _estateCtrl.dispose();
    _lotCtrl.dispose(); _waterContentCtrl.dispose(); _densityCtrl.dispose();
    _waterActivityCtrl.dispose(); _agtronCtrl.dispose(); _powderCtrl.dispose();
    _overallScoreCtrl.dispose(); _flavorsCtrl.dispose(); _cuppingScoreCtrl.dispose();
    _greenPriceCtrl.dispose(); _roastedPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final fileSize = await picked.length();
    if (fileSize > 5 * 1024 * 1024) { ErrorUtils.showError('图片大小不能超过5MB'); return; }
    try {
      final formData = dio.FormData.fromMap({'file': await dio.MultipartFile.fromFile(picked.path)});
      final res = await ApiClient.dio.post('/beans/upload-image', data: formData);
      setState(() => _imageUrl = res.data['data']['url']);
      ErrorUtils.showSuccess('图片已上传');
    } catch (e) { ErrorUtils.showError('图片上传失败'); }
  }

  Map<String, dynamic> _buildData(DateTime roastDate) {
    double? parseDouble(String s) => s.isEmpty ? null : double.tryParse(s);
    int? parseInt(String s) => s.isEmpty ? null : int.tryParse(s);
    return {
      if (_imageUrl != null && _imageUrl!.isNotEmpty) 'image': _imageUrl,
      'name': _nameCtrl.text,
      'brand': _brandCtrl.text,
      'country': _countryCtrl.text,
      'roastDate': roastDate.toIso8601String().substring(0, 10),
      'roastLevel': _roastLevelCtrl.text,
      'process': _processCtrl.text,
      'stock': double.tryParse(_stockCtrl.text) ?? 0,
      'remark': _remarkCtrl.text,
      'varieties': _varietiesCtrl.text,
      'altitude': _altitudeCtrl.text,
      'area': _areaCtrl.text,
      'productArea': _productAreaCtrl.text,
      'estate': _estateCtrl.text,
      'lot': _lotCtrl.text,
      'waterContent': _waterContentCtrl.text,
      'density': _densityCtrl.text,
      'waterActivity': _waterActivityCtrl.text,
      if (parseDouble(_agtronCtrl.text) != null) 'agtron': parseDouble(_agtronCtrl.text),
      if (parseDouble(_powderCtrl.text) != null) 'powder': parseDouble(_powderCtrl.text),
      if (parseInt(_overallScoreCtrl.text) != null) 'overallPersonalScores': parseInt(_overallScoreCtrl.text),
      'flavors': _flavorsCtrl.text,
      if (parseDouble(_cuppingScoreCtrl.text) != null) 'cuppingScores': parseDouble(_cuppingScoreCtrl.text),
      if (parseDouble(_greenPriceCtrl.text) != null) 'greenPrice': parseDouble(_greenPriceCtrl.text),
      if (parseDouble(_roastedPriceCtrl.text) != null) 'roastedPrice': parseDouble(_roastedPriceCtrl.text),
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      // 内联错误提示太靠上容易被忽略，再给一条明显的提示；停在原页面。
      ErrorUtils.showError('请填写带 * 的必填项');
      return;
    }
    // 编辑时用户没重新选日期就沿用原日期，不算必填缺失；新增时必须有日期。
    final roastDate = _roastDate ?? _originalRoastDate;
    if (roastDate == null) {
      ErrorUtils.showError('请选择烘焙日期');
      return;
    }
    final data = _buildData(roastDate);
    final ctrl = Get.find<BeanController>();
    setState(() => _submitting = true);
    bool ok;
    try {
      if (_isEdit) {
        ok = await ctrl.updateBean(_editId!, data);
      } else {
        ok = await ctrl.create(data);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!ok || !mounted) return;
    // 新增成功回传 'created'，由 MainPage 切到博物馆并提示；
    // 编辑成功回传 true，由详情页提示。
    Get.back(result: _isEdit ? true : 'created');
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboard,
        validator: (v) {
          final text = (v ?? '').trim();
          if (required && text.isEmpty) return '必填';
          if (text.isNotEmpty &&
              keyboard == TextInputType.number &&
              double.tryParse(text) == null) {
            return '请输入数字';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑咖啡豆' : '新增咖啡豆')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(7), child: ImageUtils.networkImage(_imageUrl, width: double.infinity, memCacheWidth: 900))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400), const SizedBox(height: 4), Text('点击上传咖啡豆图片', style: TextStyle(color: Colors.grey))]),
                ),
              ),
              const SizedBox(height: 12),
              _field('名称', _nameCtrl, required: true),
              _field('品牌', _brandCtrl),
              _field('生产国家', _countryCtrl, required: true),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (d != null) setState(() => _roastDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '烘焙日期 *', border: OutlineInputBorder()),
                  child: Text(_roastDate != null ? '${_roastDate!.year}-${_roastDate!.month.toString().padLeft(2, '0')}-${_roastDate!.day.toString().padLeft(2, '0')}' : '请选择'),
                ),
              ),
              const SizedBox(height: 12),
              _field('烘焙度', _roastLevelCtrl, required: true),
              _field('处理法', _processCtrl, required: true),
              _field('存量 (g)', _stockCtrl, keyboard: TextInputType.number),
              _field('备注', _remarkCtrl),
              // Collapsible "更多信息"
              ExpansionTile(
                title: const Text('更多信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                initiallyExpanded: _moreExpanded,
                onExpansionChanged: (v) => _moreExpanded = v,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _field('豆种', _varietiesCtrl),
                        _field('海拔', _altitudeCtrl),
                        _field('地区', _areaCtrl),
                        _field('产区', _productAreaCtrl),
                        _field('庄园', _estateCtrl),
                        _field('批次', _lotCtrl),
                        _field('含水量', _waterContentCtrl),
                        _field('密度', _densityCtrl),
                        _field('水活性', _waterActivityCtrl),
                        _field('色值 (Agtron)', _agtronCtrl, keyboard: TextInputType.number),
                        _field('豆粉值', _powderCtrl, keyboard: TextInputType.number),
                        _field('综合个人评分 (1-100)', _overallScoreCtrl, keyboard: TextInputType.number),
                        _field('杯测风味（逗号分隔）', _flavorsCtrl),
                        _field('杯测分数', _cuppingScoreCtrl, keyboard: TextInputType.number),
                        _field('生豆价格', _greenPriceCtrl, keyboard: TextInputType.number),
                        _field('熟豆价格', _roastedPriceCtrl, keyboard: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('提交'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
