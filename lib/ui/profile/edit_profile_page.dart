import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../controllers/user_controller.dart';
import '../../services/api_client.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import '../../utils/error_utils.dart';
import '../../utils/image_utils.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _ctrl = Get.find<UserController>();
  final _picker = ImagePicker();
  String? _avatarUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = _ctrl.profile.value;
    if (user != null) {
      _nicknameCtrl.text = user.nickname ?? '';
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.phone ?? '';
      _avatarUrl = user.avatar;
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final fileSize = await picked.length();
    if (fileSize > 5 * 1024 * 1024) {
      Get.snackbar('提示', '图片大小不能超过5MB');
      return;
    }
    setState(() => _uploading = true);
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(picked.path),
      });
      final res = await ApiClient.dio.post('/user/avatar', data: formData);
      setState(() => _avatarUrl = res.data['data']['avatar']);
      _ctrl.fetchProfile();
      Get.snackbar('成功', '头像已更新');
    } catch (e) {
      Get.snackbar('错误', '上传失败');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _ctrl.updateProfile({
      'nickname': _nicknameCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
    });
    if (ok) {
      ErrorUtils.showSuccess('资料已更新');
      Get.back();
    }
  }

  String _fullUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return '';
    if (url.startsWith('http')) return url;
    return '${AppConstants.imageBaseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: ImageUtils.avatarProvider(_fullUrl(_avatarUrl)),
                        child: _fullUrl(_avatarUrl).isEmpty
                            ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                            : null,
                      ),
                    ),
                    if (_uploading)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black38,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.primaryColor),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('点击头像更换', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()),
                validator: Validators.nickname,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: '邮箱', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: '手机号', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('保存修改'))),
            ],
          ),
        ),
      ),
    );
  }
}
