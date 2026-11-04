import 'package:get/get.dart';
import '../models/ai_setting.dart';
import '../models/ai_usage.dart';
import '../models/brew_advice.dart';
import '../services/ai_service.dart';
import '../utils/error_utils.dart';

class AiController extends GetxController {
  final AiService _service = AiService();

  final RxBool loading = false.obs;
  final Rxn<BrewAdvice> advice = Rxn<BrewAdvice>();

  /// 个人 DeepSeek 接入状态
  final Rxn<AiSetting> setting = Rxn<AiSetting>();

  /// 近 N 天 token 用量
  final Rxn<AiUsage> usage = Rxn<AiUsage>();

  final RxBool settingBusy = false.obs;

  /// 生成冲煮建议；失败时提示并返回 null。
  Future<BrewAdvice?> recommend(int beanId, {String? device, String? preference}) async {
    if (loading.value) return null;
    loading.value = true;
    try {
      final data = await _service.recommend(
        beanId: beanId,
        device: device,
        preference: preference,
      );
      final result = BrewAdvice.fromJson(data);
      advice.value = result;
      return result;
    } catch (e) {
      ErrorUtils.showError(e);
      return null;
    } finally {
      loading.value = false;
    }
  }

  Future<List<BrewAdvice>> history(int beanId) async {
    try {
      final list = await _service.history(beanId);
      return list
          .map((e) => BrewAdvice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      ErrorUtils.showError(e);
      return [];
    }
  }

  Future<void> loadSetting() async {
    try {
      final data = await _service.getSetting();
      setting.value = AiSetting.fromJson(data);
    } catch (e) {
      ErrorUtils.showError(e);
    }
  }

  Future<bool> saveKey(String apiKey) async {
    if (settingBusy.value) return false;
    settingBusy.value = true;
    try {
      final data = await _service.saveSetting(apiKey.trim());
      setting.value = AiSetting.fromJson(data);
      ErrorUtils.showSuccess('已接入你的 DeepSeek Key');
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    } finally {
      settingBusy.value = false;
    }
  }

  Future<bool> clearKey() async {
    if (settingBusy.value) return false;
    settingBusy.value = true;
    try {
      await _service.clearSetting();
      await loadSetting();
      ErrorUtils.showSuccess('已清除个人 Key');
      return true;
    } catch (e) {
      ErrorUtils.showError(e);
      return false;
    } finally {
      settingBusy.value = false;
    }
  }

  Future<void> loadUsage({int days = 14}) async {
    try {
      final data = await _service.usage(days: days);
      usage.value = AiUsage.fromJson(data);
    } catch (e) {
      ErrorUtils.showError(e);
    }
  }
}
