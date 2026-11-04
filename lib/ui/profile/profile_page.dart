import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../app/routes.dart';
import '../../utils/image_utils.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final userCtrl = Get.find<UserController>();

    userCtrl.fetchProfile();
    return Obx(() {
      final user = userCtrl.profile.value;
      return ListView(
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              if (!auth.isLoggedIn) Get.toNamed(AppRoutes.login);
            },
            child: Column(
              children: [
                Builder(builder: (ctx) {
                  final avatar = ImageUtils.avatarProvider(user?.avatar);
                  return CircleAvatar(
                    radius: 42,
                    backgroundImage: avatar,
                    child: avatar == null ? const Icon(Icons.person, size: 42) : null,
                  );
                }),
                const SizedBox(height: 10),
                Text(user?.nickname ?? '未登录', style: Theme.of(context).textTheme.titleMedium),
                if (user != null) Text('@${user.username}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user != null) ...[
            _section('账户管理'),
            _tile(Icons.person_outline, '编辑资料', () => Get.toNamed(AppRoutes.editProfile)),
            _tile(Icons.lock_outline, '修改密码', () => Get.toNamed(AppRoutes.changePassword)),
            _tile(Icons.vpn_key_outlined, '刷新本地令牌', () => _refreshToken(auth)),
            _tile(Icons.psychology_outlined, 'AI 管理', () => Get.toNamed(AppRoutes.aiCenter)),
            const Divider(indent: 16, endIndent: 16),
          ],
          _section('偏好'),
          _tile(Icons.palette_outlined, '主题与字体', () => Get.toNamed(AppRoutes.settings)),
          _tile(Icons.notifications_outlined, '通知', () => Get.snackbar('提示', '功能待完善')),
          const Divider(indent: 16, endIndent: 16),
          _section('其他'),
          _tile(Icons.cloud_outlined, '数据管理', () => Get.snackbar('提示', '功能待完善')),
          _tile(Icons.help_outline, '帮助与反馈', () => _showHelp()),
          _tile(Icons.info_outline, '关于', () => _showAbout()),
          const Divider(indent: 16, endIndent: 16),
          if (user != null) ...[
            _tile(Icons.switch_account, '切换账号', () => _switchAccount(auth)),
            _tile(Icons.logout, '退出登录', () => _logout(auth), color: Colors.orange),
            _tile(Icons.delete_forever, '注销账号', () => _deleteAccount(userCtrl, auth), color: Colors.red),
            const SizedBox(height: 40),
          ],
        ],
      );
    });
  }

  void _refreshToken(AuthController auth) async {
    try {
      await AuthService().refresh();
      Get.snackbar('成功', '令牌已刷新', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('失败', '刷新失败，请重新登录', snackPosition: SnackPosition.BOTTOM);
      StorageService.clearAuth();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _switchAccount(AuthController auth) async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('切换账号'),
      content: const Text('将清除当前登录信息并返回登录页'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('确定')),
      ],
    ));
    if (confirm == true) {
      StorageService.clearAuth();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _logout(AuthController auth) async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出登录吗？'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('退出')),
      ],
    ));
    if (confirm == true) {
      await auth.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showHelp() {
    Get.dialog(AlertDialog(
      title: const Text('帮助与反馈'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('反馈邮箱: feedback@yucafe.com'),
          SizedBox(height: 8),
          Text('GitHub: github.com/yucafe'),
        ],
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('关闭'))],
    ));
  }

  void _showAbout() {
    Get.dialog(AlertDialog(
      title: const Text('关于芋咖记'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('版本: 1.0.0'),
          SizedBox(height: 8),
          Text('一款方便咖啡爱好者记录冲煮参数的应用'),
        ],
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('关闭'))],
    ));
  }

  Future<void> _deleteAccount(UserController userCtrl, AuthController auth) async {
    final first = await Get.dialog<bool>(AlertDialog(
      title: const Text('警告'), content: const Text('确定要注销账户吗？此操作不可撤销。'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('确定', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (first != true) return;
    final second = await Get.dialog<bool>(AlertDialog(
      title: const Text('最终确认'), content: const Text('所有数据将被永久删除，确认注销？'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('确认注销', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (second != true) return;
    final pwdCtrl = TextEditingController();
    final password = await Get.dialog<String>(AlertDialog(
      title: const Text('验证密码'),
      content: TextField(
        controller: pwdCtrl,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: '登录密码'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        TextButton(
          onPressed: () => Get.back(result: pwdCtrl.text),
          child: const Text('注销', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
    if (password == null || password.isEmpty) {
      Get.snackbar('提示', '请输入密码后重试');
      return;
    }
    // deleteAccount 返回 bool：失败时其内部已弹过错误提示，这里只需判断成功与否。
    final ok = await userCtrl.deleteAccount(password);
    if (!ok) return;
    await auth.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
  );

  Widget _tile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, color: color)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      dense: true,
    );
  }
}
