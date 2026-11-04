import 'package:flutter/material.dart';

/// App 级 ScaffoldMessenger 的 key。
///
/// 提示条如果挂在当前页面的 GetX overlay 上，页面一 pop 提示就跟着消失
/// （这正是「删除成功后什么都没看到」的原因）。挂在 MaterialApp 级别的
/// ScaffoldMessenger 上，提示就能跨页面存活。
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
