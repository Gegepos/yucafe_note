import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../utils/error_utils.dart';
import '../../utils/image_cache.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _themeMode = 'system';
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _themeMode = StorageService.themeMode ?? 'system';
    _fontSize = StorageService.fontSize;
  }

  void _setTheme(String mode) {
    setState(() => _themeMode = mode);
    StorageService.themeMode = mode;
    ThemeMode themeMode;
    switch (mode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    Get.changeThemeMode(themeMode);
  }

  void _setFontSize(double size) {
    setState(() => _fontSize = size);
    StorageService.fontSize = size;
  }

  Future<void> _clearImageCache() async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('清除图片缓存'),
      content: const Text('会删除已下载的咖啡豆图片和头像，下次查看时重新下载。\n不影响你的豆子和笔记数据。'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('清除')),
      ],
    ));
    if (confirm != true) return;
    await YuCafeImageCache.clear();
    // 内存里的解码结果也一并丢掉，否则清完看起来没变化。
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    ErrorUtils.showSuccess('图片缓存已清除');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('偏好设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('主题模式', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('日间')),
              ButtonSegment(value: 'dark', label: Text('夜间')),
              ButtonSegment(value: 'system', label: Text('跟随系统')),
            ],
            selected: {_themeMode},
            onSelectionChanged: (s) => _setTheme(s.first),
          ),
          const SizedBox(height: 24),
          Text('主题色', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('咖啡棕 #7A5448 (默认)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Text('字体大小', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _fontSize,
            min: 12,
            max: 18,
            divisions: 6,
            label: '${_fontSize.round()}px',
            onChanged: _setFontSize,
          ),
          const SizedBox(height: 16),
          Text('存储', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined),
            title: const Text('清除图片缓存'),
            subtitle: const Text('豆子图片与头像会重新下载'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearImageCache,
          ),
        ],
      ),
    );
  }
}
