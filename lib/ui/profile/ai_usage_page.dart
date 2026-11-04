import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/ai_controller.dart';
import '../../models/ai_usage.dart';
import '../widgets/loader.dart';

/// 近期 token 用量图表。
class AiUsagePage extends StatefulWidget {
  const AiUsagePage({super.key});

  @override
  State<AiUsagePage> createState() => _AiUsagePageState();
}

class _AiUsagePageState extends State<AiUsagePage> {
  final AiController _ctrl = Get.find<AiController>();

  @override
  void initState() {
    super.initState();
    _ctrl.loadUsage(days: 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token 用量')),
      body: Obx(() {
        final usage = _ctrl.usage.value;
        if (usage == null) {
          return const AppLoading(text: '正在加载用量…');
        }
        return RefreshIndicator(
          onRefresh: () => _ctrl.loadUsage(days: usage.days == 0 ? 14 : usage.days),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(context, usage),
              const SizedBox(height: 16),
              _chartCard(context, usage),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard(BuildContext context, AiUsage usage) {
    final theme = Theme.of(context);
    final avg = usage.totalCalls == 0 ? 0 : usage.totalTokens ~/ usage.totalCalls;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近 ${usage.days} 天', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric(context, '总 tokens', _compact(usage.totalTokens)),
                _metric(context, '调用次数', '${usage.totalCalls}'),
                _metric(context, '平均每次', _compact(avg)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '输入 ${_compact(usage.totalPromptTokens)} · 输出 ${_compact(usage.totalCompletionTokens)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, AiUsage usage) {
    final theme = Theme.of(context);
    final empty = usage.points.isEmpty || usage.totalTokens == 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text('每日用量', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  _legendDot(theme, theme.colorScheme.primary, '输出'),
                  const SizedBox(width: 12),
                  _legendDot(theme, theme.colorScheme.primary.withValues(alpha: 0.35), '输入'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (empty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    '近 ${usage.days} 天还没有 AI 调用记录',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                width: double.infinity,
                child: CustomPaint(
                  painter: _UsageBarPainter(
                    points: usage.points,
                    barColor: theme.colorScheme.primary,
                    gridColor: theme.colorScheme.outlineVariant,
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ) ??
                        const TextStyle(fontSize: 10),
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }
}

/// 堆叠柱状图：下层为 completion（输出），上层为 prompt（输入）。
class _UsageBarPainter extends CustomPainter {
  final List<AiUsagePoint> points;
  final Color barColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final TextDirection textDirection;

  _UsageBarPainter({
    required this.points,
    required this.barColor,
    required this.gridColor,
    required this.labelStyle,
    required this.textDirection,
  });

  final double _leftPad = 38;
  final double _rightPad = 4;
  final double _topPad = 10;
  final double _bottomPad = 22;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final plotWidth = size.width - _leftPad - _rightPad;
    final plotHeight = size.height - _topPad - _bottomPad;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final maxTotal = points
        .map((p) => p.total)
        .fold<int>(0, (a, b) => math.max(a, b));
    final niceMax = _niceCeil(maxTotal == 0 ? 1 : maxTotal);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.6;

    // 网格线 + y 轴刻度
    const divisions = 4;
    for (var i = 0; i <= divisions; i++) {
      final ratio = i / divisions;
      final y = _topPad + plotHeight * (1 - ratio);
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width - _rightPad, y), gridPaint);
      final label = _yLabel((niceMax * ratio).round());
      _drawText(
        canvas,
        label,
        Offset(_leftPad - 6, y),
        align: TextAlign.right,
        anchor: _TextAnchor.rightCenter,
      );
    }

    // 柱子
    final slot = plotWidth / points.length;
    final barWidth = math.min(slot * 0.62, 22.0);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.total == 0) continue;
      final cx = _leftPad + slot * i + slot / 2;
      final left = cx - barWidth / 2;

      final completionH = plotHeight * (p.completionTokens / niceMax);
      final promptH = plotHeight * (p.promptTokens / niceMax);

      // 输出（实色）在下
      final baseY = _topPad + plotHeight;
      if (completionH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, baseY - completionH, barWidth, completionH),
            topLeft: Radius.circular(promptH > 0 ? 0 : 3),
            topRight: Radius.circular(promptH > 0 ? 0 : 3),
            bottomLeft: const Radius.circular(3),
            bottomRight: const Radius.circular(3),
          ),
          Paint()..color = barColor,
        );
      }
      // 输入（半透明）在上
      if (promptH > 0) {
        final top = baseY - completionH - promptH;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, top, barWidth, promptH),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()..color = barColor.withValues(alpha: 0.35),
        );
      }
    }

    // x 轴日期标签：最多显示 7 个
    final step = math.max(1, (points.length / 7).ceil());
    for (var i = 0; i < points.length; i++) {
      if (i % step != 0 && i != points.length - 1) continue;
      final cx = _leftPad + slot * i + slot / 2;
      _drawText(
        canvas,
        points[i].shortDate,
        Offset(cx, size.height - _bottomPad + 6),
        align: TextAlign.center,
        anchor: _TextAnchor.topCenter,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchorPoint, {
    TextAlign align = TextAlign.left,
    required _TextAnchor anchor,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: textDirection,
      textAlign: align,
    )..layout();
    Offset offset;
    switch (anchor) {
      case _TextAnchor.rightCenter:
        offset = Offset(anchorPoint.dx - tp.width, anchorPoint.dy - tp.height / 2);
        break;
      case _TextAnchor.topCenter:
        offset = Offset(anchorPoint.dx - tp.width / 2, anchorPoint.dy);
        break;
      case _TextAnchor.leftCenter:
        offset = Offset(anchorPoint.dx, anchorPoint.dy - tp.height / 2);
        break;
    }
    tp.paint(canvas, offset);
  }

  String _yLabel(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    return '$value';
  }

  /// 把最大值向上取整到“能被 4 整除”的刻度上限，保证 y 轴每格都是整数。
  int _niceCeil(int value) {
    const ladder = <int>[
      4, 8, 12, 16, 20, 24, 40, 80, 120, 160, 200, 240,
      400, 800, 1200, 1600, 2000, 2400, 4000, 8000, 12000, 16000,
      20000, 24000, 40000, 80000, 120000, 160000, 200000, 240000,
      400000, 800000, 1200000, 1600000, 2000000,
    ];
    for (final step in ladder) {
      if (step >= value) return step;
    }
    return ((value / 4).ceil() * 4);
  }

  @override
  bool shouldRepaint(covariant _UsageBarPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor;
  }
}

enum _TextAnchor { rightCenter, topCenter, leftCenter }
