import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 全站共用的图片磁盘缓存。
///
/// Flutter 自带的 `ImageCache` 只在内存里、跨进程就没了；这里用
/// flutter_cache_manager 把图片落到磁盘，App 重启后依然命中，
/// 同一张豆子图、同一个头像只会真正下载一次。
///
/// 默认配置是 200 个对象 / 30 天，对「一人几十支豆子、每支一张图」的场景偏紧，
/// 这里放宽到 800 个对象 / 90 天。图片文件名是服务端生成的 UUID，
/// 内容不会变，缓存久一点不会有旧图问题。
class YuCafeImageCache {
  static const String cacheKey = 'yucafe_images';

  static final CacheManager instance = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 800,
    ),
  );

  /// 清空磁盘缓存（设置页的「清除图片缓存」用）。
  static Future<void> clear() => instance.emptyCache();
}
