import 'package:flutter/material.dart';
import '../../models/coffee_bean.dart';
import '../../utils/image_utils.dart';
import '../../utils/roast_freshness.dart';

/// 博物馆里的咖啡豆卡片。
///
/// 默认只渲染一行摘要（不加载图片）。点右侧箭头展开，展开后才请求并显示图片；
/// 点卡片其他区域仍然直接进入详情页，这样列表首屏不需要为每支豆子发一次图片请求。
class BeanCard extends StatelessWidget {
  final CoffeeBean bean;

  /// 点击卡片主体：进入详情页（多选态下由外部改成切换选中）。
  final VoidCallback onTap;

  /// 点击右侧箭头：展开 / 收起。
  final VoidCallback? onToggleExpand;

  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;
  final bool expanded;

  const BeanCard({
    super.key,
    required this.bean,
    required this.onTap,
    this.onToggleExpand,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: expanded ? 4 : 2,
      shadowColor: isLight
          ? Colors.brown.withValues(alpha: 0.2)
          : Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, isLight),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? _expandedBody(context, isLight)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
            if (selecting)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : Colors.black26,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool isLight) {
    final brand = bean.brand?.trim() ?? '';
    final fresh = Freshness.from(
      roastDate: bean.roastDate,
      roastLevel: bean.roastLevel,
    );
    final showSubtitle = brand.isNotEmpty || fresh.isKnown;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isLight ? Colors.brown.shade50 : Colors.brown.shade900,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.coffee,
              size: 18,
              color: isLight ? Colors.brown.shade400 : Colors.brown.shade200,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bean.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (brand.isNotEmpty)
                          TextSpan(
                            text: brand,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        if (brand.isNotEmpty && fresh.isKnown)
                          const TextSpan(text: '  ·  '),
                        if (fresh.isKnown)
                          TextSpan(
                            text: '● ${fresh.label}',
                            style: TextStyle(
                              color: fresh.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${bean.stock.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLight ? Colors.brown.shade700 : Colors.brown.shade200,
            ),
          ),
          // 独立命中区域，避免和「点卡片进详情」冲突。
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tooltip: expanded ? '收起' : '展开图片',
              onPressed: onToggleExpand,
              icon: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 展开后才构建，图片因此才真正开始下载。
  Widget _expandedBody(BuildContext context, bool isLight) {
    final hasImage = ImageUtils.resolveUrl(bean.image).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          // 图片单独成层：滚动时不会把整张卡片一起重绘。
          RepaintBoundary(
            child: ImageUtils.networkImage(
              bean.image,
              height: 150,
              memCacheWidth: 900,
            ),
          )
        else
          Container(
            height: 72,
            color: isLight ? Colors.brown.shade50 : Colors.brown.shade900,
            child: Icon(
              Icons.coffee,
              size: 28,
              color: isLight ? Colors.brown.shade200 : Colors.brown.shade700,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(bean.roastLevel),
              if (bean.country.isNotEmpty) _tag(bean.country),
              if (bean.process.isNotEmpty) _tag(bean.process),
              if (bean.roastDate.isNotEmpty) _tag('烘焙 ${bean.roastDate}'),
              _tag('库存 ${bean.stock.toStringAsFixed(0)} g'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.brown.shade700),
      ),
    );
  }
}
