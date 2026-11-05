import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../ui/add/add_bean_page.dart';
import '../ui/add/add_note_page.dart';
import '../ui/auth/login_page.dart';
import '../ui/auth/register_page.dart';
import '../ui/main_page.dart';
import '../ui/museum/bean_detail_page.dart';
import '../ui/notes/note_detail_page.dart';
import '../ui/profile/ai_center_page.dart';
import '../ui/profile/ai_usage_page.dart';
import '../ui/profile/change_password_page.dart';
import '../ui/profile/edit_profile_page.dart';
import '../ui/profile/settings_page.dart';
import '../ui/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String beanDetail = '/beans/detail';
  static const String addBean = '/beans/add';
  static const String addNote = '/notes/add';
  static const String noteDetail = '/notes/detail';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/password';
  static const String settings = '/profile/settings';
  static const String aiCenter = '/profile/ai';
  static const String aiUsage = '/profile/ai/usage';

  static final pages = [
    // 启动页不挂 AuthGuard：它自己负责初始化并决定跳登录页还是首页。
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(
      name: home,
      page: () => const MainPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: register, page: () => const RegisterPage()),
    GetPage(
      name: beanDetail,
      page: () => const BeanDetailPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: addBean,
      page: () => const AddBeanPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: addNote,
      page: () => const AddNotePage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: noteDetail,
      page: () => const NoteDetailPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfilePage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: changePassword,
      page: () => const ChangePasswordPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: aiCenter,
      page: () => const AiCenterPage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: aiUsage,
      page: () => const AiUsagePage(),
      middlewares: [AuthGuard()],
    ),
  ];
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!StorageService.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
