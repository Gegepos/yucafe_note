import 'package:flutter/material.dart';

import 'app/app.dart';

/// 启动链路拆成两段：
/// 1. 这里只负责把 UI 立起来，让首帧尽快上屏；
/// 2. 本地存储、网络层、控制器的初始化全部挪到 `SplashPage`，
///    在启动动画播放期间完成 —— 避免 `runApp` 之前的 await 变成白屏时间。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YuCafeApp());
}
