import 'package:get/get.dart';
import '../services/dashboard_service.dart';

class DashboardController extends GetxController {
  final DashboardService _service = DashboardService();
  final weeklyBrewCount = 0.obs;
  final totalStock = 0.0.obs;
  final daysSinceLastBrew = Rxn<int>();
  final beanCount = 0.obs;
  final favorites = [].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final summary = await _service.getSummary();
      weeklyBrewCount.value = summary['weeklyBrewCount'] ?? 0;
      totalStock.value = (summary['totalStock'] ?? 0).toDouble();
      daysSinceLastBrew.value = summary['daysSinceLastBrew'];
      beanCount.value = summary['beanCount'] ?? 0;

      final favs = await _service.getFavorites();
      favorites.value = favs;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }
}
