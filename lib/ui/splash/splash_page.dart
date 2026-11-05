import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../app/routes.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/bean_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/main_tab_controller.dart';
import '../../controllers/note_controller.dart';
import '../../controllers/user_controller.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';

/// 启动页：一杯咖啡被逐渐注满，同时完成应用初始化。
///
/// 之所以把初始化放在这里而不是 `main()` 里 `await`，是因为 `runApp` 之前的
/// 任何 await 都会变成用户的**白屏时间**；放到首帧之后，用户看到的是动画，
/// 而不是黑屏。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  /// 注满一杯的时长，同时也是启动页的最短停留时间。
  static const Duration _fillDuration = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fillDuration,
  );

  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 初始化依赖（本地存储 → 网络层 → 控制器），完成后再跳转。
  Future<void> _bootstrap() async {
    try {
      // 必须先于 ApiClient.init()：拦截器要读取本地 token。
      await GetStorage.init();
      ApiClient.init();
      _registerControllers();

      // 初始化很快时也让动画走完，避免启动页闪一下就没了。
      await _waitForFillAnimation();

      if (!mounted) return;
      _goNext();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  /// 等「注满一杯」的动画播完（它就是启动页的最短停留时间）。
  Future<void> _waitForFillAnimation() {
    if (_controller.status == AnimationStatus.completed) {
      return Future<void>.value();
    }
    final done = Completer<void>();
    void check() {
      if (_controller.status == AnimationStatus.completed &&
          !done.isCompleted) {
        _controller.removeListener(check);
        done.complete();
      }
    }

    _controller.addListener(check);
    check();
    return done.future;
  }

  void _registerControllers() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    if (!Get.isRegistered<BeanController>()) {
      Get.put(BeanController(), permanent: true);
    }
    if (!Get.isRegistered<NoteController>()) {
      Get.put(NoteController(), permanent: true);
    }
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController(), permanent: true);
    }
    if (!Get.isRegistered<MainTabController>()) {
      Get.put(MainTabController(), permanent: true);
    }
    if (!Get.isRegistered<AiController>()) {
      Get.put(AiController(), permanent: true);
    }
  }

  void _goNext() {
    // 主题存在本地，首帧时还没读到，这里补一次应用。
    final stored = StorageService.themeMode;
    if (stored == 'light') {
      Get.changeThemeMode(ThemeMode.light);
    } else if (stored == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.system);
    }
    Get.offAllNamed(
      StorageService.isLoggedIn ? AppRoutes.home : AppRoutes.login,
    );
  }

  void _retry() {
    setState(() => _error = null);
    _controller
      ..reset()
      ..forward();
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF282A36) : const Color(0xFFFDF8F4);
    final fg = isDark ? const Color(0xFFF8F8F2) : const Color(0xFF7A5448);

    return Scaffold(
      backgroundColor: bg,
      body: Center(child: _error == null ? _buildLoading(fg) : _buildError(fg)),
    );
  }

  Widget _buildLoading(Color fg) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(150, 132),
              painter: CoffeeCupPainter(progress: _controller.value, color: fg),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          '芋咖记',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _controller.value.clamp(0.0, 1.0),
              child: Text(
                '正在为你磨豆…',
                style: TextStyle(
                  fontSize: 12,
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildError(Color fg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_cafe_outlined,
            size: 48,
            color: fg.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            '启动失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_error',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _retry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 画一只被逐渐注满的咖啡杯。
///
/// 公开是为了能在测试里离屏渲染出来核对视觉。
class CoffeeCupPainter extends CustomPainter {
  CoffeeCupPainter({required this.progress, required this.color});

  /// 0 = 空杯，1 = 满杯。
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // 杯子主体：上宽下窄的圆角梯形。
    const topW = 92.0;
    const bottomW = 74.0;
    const bodyH = 82.0;
    final centerX = size.width / 2;
    final topY = 16.0;
    final bottomY = topY + bodyH;

    final body = Path()
      ..moveTo(centerX - topW / 2, topY)
      ..lineTo(centerX - bottomW / 2, bottomY - 10)
      ..quadraticBezierTo(
        centerX - bottomW / 2,
        bottomY,
        centerX - bottomW / 2 + 10,
        bottomY,
      )
      ..lineTo(centerX + bottomW / 2 - 10, bottomY)
      ..quadraticBezierTo(
        centerX + bottomW / 2,
        bottomY,
        centerX + bottomW / 2,
        bottomY - 10,
      )
      ..lineTo(centerX + topW / 2, topY)
      ..close();

    // 液面：从杯底往上涨，留 6px 空隙避免看着要溢出。
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(body);
      final innerBottom = bottomY - 3;
      final innerTop = topY + 6;
      final liquidTop =
          innerBottom - (innerBottom - innerTop) * progress.clamp(0.0, 1.0);
      final liquid = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.9)],
        ).createShader(Rect.fromLTRB(0, liquidTop, size.width, innerBottom));
      canvas.drawRect(
        Rect.fromLTRB(0, liquidTop, size.width, innerBottom + 2),
        liquid,
      );
      // 液面那一道亮边。
      canvas.drawLine(
        Offset(centerX - topW / 2, liquidTop),
        Offset(centerX + topW / 2, liquidTop),
        Paint()
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: 0.5),
      );
      canvas.restore();
    }

    canvas.drawPath(body, stroke);

    // 杯子把手：从杯口右侧伸出、绕一圈再贴回杯身。
    final hx = centerX + topW / 2;
    final handle = Path()
      ..moveTo(hx - 3, topY + 24)
      ..cubicTo(hx + 24, topY + 20, hx + 24, topY + 52, hx - 8, topY + 50);
    canvas.drawPath(handle, stroke);

    // 杯碟。
    canvas.drawLine(
      Offset(centerX - topW / 2 - 12, bottomY + 10),
      Offset(centerX + topW / 2 + 12, bottomY + 10),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.75),
    );

    // 快满的时候冒热气。
    final steam = ((progress - 0.72) / 0.28).clamp(0.0, 1.0);
    if (steam > 0) {
      final steamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35 * steam);
      for (var i = 0; i < 3; i++) {
        final dx = centerX - 18 + i * 18.0;
        final path = Path()
          ..moveTo(dx, topY - 4)
          ..quadraticBezierTo(dx + 5, topY - 12, dx, topY - 20)
          ..quadraticBezierTo(dx - 5, topY - 28, dx, topY - 34);
        canvas.drawPath(path, steamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CoffeeCupPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
