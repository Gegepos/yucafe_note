import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../utils/app_keys.dart';
import 'routes.dart';

class YuCafeApp extends StatelessWidget {
  const YuCafeApp({super.key});

  static const _coffeeBrown = Color(0xFF7A5448);
  static const _cream = Color(0xFFFDF8F4);

  // Dracula Theme colors
  static const _draculaBg = Color(0xFF282A36);
  static const _draculaSurface = Color(0xFF44475A);
  static const _draculaFg = Color(0xFFF8F8F2);
  static const _draculaPurple = Color(0xFFBD93F9);
  static const _draculaPink = Color(0xFFFF79C6);

  @override
  Widget build(BuildContext context) {
    final themeModeStr = StorageService.themeMode ?? 'system';
    ThemeMode themeMode;
    switch (themeModeStr) {
      case 'light': themeMode = ThemeMode.light;
      case 'dark': themeMode = ThemeMode.dark;
      default: themeMode = ThemeMode.system;
    }

    return GetMaterialApp(
      title: '芋咖记',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _coffeeBrown,
          brightness: Brightness.light,
          surface: _cream,
        ),
        scaffoldBackgroundColor: _cream,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _coffeeBrown,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: _coffeeBrown.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: _coffeeBrown,
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _coffeeBrown,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _coffeeBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _draculaPurple,
          secondary: _draculaPink,
          surface: _draculaBg,
          onPrimary: _draculaBg,
          onSecondary: _draculaBg,
          onSurface: _draculaFg,
        ),
        scaffoldBackgroundColor: _draculaBg,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _draculaSurface,
          foregroundColor: _draculaFg,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: _draculaSurface,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _draculaSurface,
          selectedItemColor: _draculaPurple,
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _draculaPurple,
          foregroundColor: _draculaBg,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _draculaPurple,
            foregroundColor: _draculaBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      initialRoute: StorageService.isLoggedIn ? '/' : '/login',
      getPages: AppRoutes.pages,
    );
  }
}
