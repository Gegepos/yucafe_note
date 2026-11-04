import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../utils/validators.dart';
import '../../utils/error_utils.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await Get.find<UserController>().changePassword(_oldCtrl.text, _newCtrl.text);
    if (ok) {
      ErrorUtils.showSuccess('密码已修改');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: '旧密码', border: OutlineInputBorder()), validator: Validators.password),
              const SizedBox(height: 12),
              TextFormField(controller: _newCtrl, obscureText: true, decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()), validator: Validators.password),
              const SizedBox(height: 12),
              TextFormField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: '确认新密码', border: OutlineInputBorder()), validator: (v) => Validators.confirmPassword(v, _newCtrl.text)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text('确认修改'))),
            ],
          ),
        ),
      ),
    );
  }
}
