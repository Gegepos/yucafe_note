import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/auth_controller.dart';
import 'controllers/bean_controller.dart';
import 'controllers/note_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/main_tab_controller.dart';
import 'controllers/ai_controller.dart';
import 'services/api_client.dart';
import 'app/app.dart';

void main() async {
  await GetStorage.init();
  ApiClient.init();
  Get.put(AuthController(), permanent: true);
  Get.put(BeanController(), permanent: true);
  Get.put(NoteController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(DashboardController(), permanent: true);
  Get.put(MainTabController(), permanent: true);
  Get.put(AiController(), permanent: true);
  runApp(const YuCafeApp());
}
