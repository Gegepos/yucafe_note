import 'package:flutter/material.dart';

/// 骨架屏色块：自带横向流光动画，用于列表占位与图片加载中的占位。
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height, this.borderRadius});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // 与咖啡奶油底同色系的骨架色，避免灰块突兀。
    final base = isLight ? const Color(0xFFEDE2DA) : const Color(0xFF37302E);
    final highlight = isLight ? const Color(0xFFFAF5F1) : const Color(0xFF4B403C);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 - 1; // -1 → 1，光带从左扫到右
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 页面级加载动画：品牌色的旋转圆环 + 呼吸的咖啡杯图标。
class AppLoading extends StatefulWidget {
  const AppLoading({super.key, this.text});

  final String? text;

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.82, end: 1.05).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Icon(Icons.coffee, size: 22, color: primary),
                ),
              ],
            ),
          ),
          if (widget.text != null) ...[
            const SizedBox(height: 14),
            Text(widget.text!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}

/// 列表骨架：形状贴近真实卡片，避免「转圈 → 内容」的跳变。
class CardListSkeleton extends StatelessWidget {
  const CardListSkeleton({super.key, this.count = 6, this.height = 76});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
      itemCount: count,
      itemBuilder: (context, index) => Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const ShimmerBox(width: 36, height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(18))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 12, width: 150),
                    SizedBox(height: 8),
                    ShimmerBox(height: 10, width: 96),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(height: 12, width: 42),
            ],
          ),
        ),
      ),
    );
  }
}
