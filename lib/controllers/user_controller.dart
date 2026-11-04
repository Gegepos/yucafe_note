import 'package:get/get.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/error_utils.dart';

class UserController extends GetxController {
  final UserService _service = UserService();
  final profile = Rxn<User>();
  final isLoading = false.obs;

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try { final data = await _service.getProfile(); profile.value = User.fromJson(data); }
    catch (_) {} finally { isLoading.value = false; }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try { await _service.updateProfile(data); await fetchProfile(); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  Future<bool> changePassword(String oldPwd, String newPwd) async {
    try { await _service.changePassword(oldPwd, newPwd); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }

  Future<bool> deleteAccount(String password) async {
    try { await _service.deleteAccount(password); return true; }
    catch (e) { ErrorUtils.showError(e); return false; }
  }
}
