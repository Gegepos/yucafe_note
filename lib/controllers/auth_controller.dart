import 'package:get/get.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/error_utils.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final user = Rxn<User>();
  final isLoading = false.obs;

  bool get isLoggedIn => StorageService.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  Future<void> checkAuth() async {
    if (!StorageService.isLoggedIn) return;
    try {
      final data = await _authService.refresh();
      user.value = User.fromJson(data);
    } catch (_) {
      StorageService.clearAuth();
    }
  }

  Future<bool> register({
    required String username, required String password,
    required String nickname, required String confirmPassword,
  }) async {
    isLoading.value = true;
    try {
      final data = await _authService.register(
        username: username, password: password,
        nickname: nickname, confirmPassword: confirmPassword,
      );
      user.value = User.fromJson(data);
      ErrorUtils.showSuccess('注册成功');
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    try {
      final data = await _authService.login(username, password);
      user.value = User.fromJson(data);
      ErrorUtils.showSuccess('登录成功');
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
  }
}
