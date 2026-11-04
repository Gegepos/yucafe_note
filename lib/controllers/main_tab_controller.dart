import 'package:get/get.dart';

/// 底部导航的当前下标。
///
/// 之前这个值藏在 MainPage 的 State 里，别的页面没法改。放到控制器后，
/// 新增页成功后可以直接把界面切到「博物馆」/「笔记」。
class MainTabController extends GetxController {
  final index = 0.obs;

  void go(int i) => index.value = i;
}
