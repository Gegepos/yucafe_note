import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import '../ui/widgets/loader.dart';
import 'image_cache.dart';

class ImageUtils {
  static const _baseUrl = AppConstants.imageBaseUrl;

  static String resolveUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null' || url == '<null>') return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_baseUrl$url';
    return '';
  }

  /// 网络图片：命中磁盘/内存缓存时直接显示，否则显示流光骨架 → 淡入。
  ///
  /// [memCacheWidth] 用来限制解码尺寸：列表缩略图传个 200 左右，
  /// 能让一张 4000px 的原图只占很少的内存，也不会在滚动时反复重解码。
  static Widget networkImage(
    String? url, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    int? memCacheWidth,
  }) {
    final resolved = resolveUrl(url);
    if (resolved.isEmpty) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: resolved,
      cacheManager: YuCafeImageCache.instance,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: memCacheWidth,
      // 缓存命中时不会走 placeholder，直接从磁盘读出来就渲染。
      fadeInDuration: const Duration(milliseconds: 260),
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) => ShimmerBox(
        width: width,
        height: height,
        borderRadius: BorderRadius.zero,
      ),
      errorWidget: (context, _, _) => Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  /// 头像专用 ImageProvider（同样走磁盘缓存）。
  static ImageProvider? avatarProvider(String? url) {
    final resolved = resolveUrl(url);
    if (resolved.isEmpty) return null;
    return CachedNetworkImageProvider(
      resolved,
      cacheManager: YuCafeImageCache.instance,
      maxWidth: 200,
      maxHeight: 200,
    );
  }
}
