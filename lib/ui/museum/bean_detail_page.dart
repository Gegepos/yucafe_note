import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bean_controller.dart';
import '../../app/routes.dart';
import '../../utils/image_utils.dart';
import '../../utils/flavor_colors.dart';
import '../../utils/error_utils.dart';
import '../../utils/roast_freshness.dart';
import '../widgets/loader.dart';

class BeanDetailPage extends StatefulWidget {
  const BeanDetailPage({super.key});
  @override
  State<BeanDetailPage> createState() => _BeanDetailPageState();
}

class _BeanDetailPageState extends State<BeanDetailPage> {
  late final int _id = Get.arguments as int;
  late final BeanController _ctrl = Get.find<BeanController>();
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = _ctrl.fetchDetail(_id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(body: AppLoading(text: '正在加载咖啡豆…'));
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text('加载失败')));
        if (!snapshot.hasData)
          return const Scaffold(body: Center(child: Text('数据为空')));
        final bean = snapshot.data!;
        final fresh = Freshness.from(
          roastDate: bean.roastDate,
          roastLevel: bean.roastLevel,
        );
        return Scaffold(
          appBar: AppBar(title: Text(bean.name), actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () async {
              final changed = await Get.toNamed(AppRoutes.addBean, arguments: bean);
              if (changed == true && mounted) {
                ErrorUtils.showSuccess('修改成功');
                setState(() => _future = _ctrl.fetchDetail(_id));
              }
            }),
            IconButton(icon: const Icon(Icons.delete), onPressed: () async {
              final confirm = await Get.dialog<bool>(AlertDialog(
                title: const Text('删除确认'),
                content: const Text('确定删除此咖啡豆记录？\n关联的冲煮笔记也会一并删除。'),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
                  TextButton(onPressed: () => Get.back(result: true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ));
              if (confirm != true) return;
              final ok = await _ctrl.delete(_id);
              if (!ok) return;
              // 提示交给博物馆页在返回后展示，避免 snackbar 随路由一起被销毁。
              Get.back(result: true);
            }),
          ]),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ImageUtils.resolveUrl(bean.image).isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: ImageUtils.networkImage(bean.image, height: 200, width: double.infinity, memCacheWidth: 1080)),
                const SizedBox(height: 16),
                if (fresh.isKnown) ...[
                  _freshnessBanner(fresh),
                  const SizedBox(height: 16),
                ],
                _section('基本信息'),
                _row('名称', bean.name), _row('品牌', bean.brand ?? '-'), _row('豆种', bean.varieties ?? '-'),
                _row('国家', bean.country), _row('产区', bean.productArea ?? '-'), _row('地区', bean.area ?? '-'),
                _row('庄园', bean.estate ?? '-'), _row('海拔', bean.altitude ?? '-'), _row('批次', bean.lot ?? '-'),
                const SizedBox(height: 12),
                _section('烘焙信息'),
                _row('烘焙日期', bean.roastDate), _row('烘焙度', bean.roastLevel), _row('处理法', bean.process),
                const SizedBox(height: 12),
                _section('杯测数据'),
                _row('杯测分数', bean.cuppingScores?.toString() ?? '-'),
                _row('个人评分', bean.overallPersonalScores?.toString() ?? '-'),
                _buildFlavorChips(bean.flavors ?? ''),
                _row('色值', bean.agtron?.toString() ?? '-'),
                _row('豆粉值', bean.powder?.toString() ?? '-'),
                const SizedBox(height: 12),
                _section('库存与价格'),
                _row('存量', '${bean.stock}g'),
                _row('生豆价格', bean.greenPrice != null ? '${bean.greenPrice}元/kg' : '-'),
                _row('熟豆价格', bean.roastedPrice != null ? '${bean.roastedPrice}元/kg' : '-'),
                if (bean.remark != null && bean.remark!.isNotEmpty) ...[
                  const SizedBox(height: 12), _section('备注'), Text(bean.remark!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlavorChips(String flavors) {
    if (flavors.isEmpty) return const SizedBox.shrink();
    final list = flavors.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4), Text('风味', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: list.map((f) {
          final bg = FlavorColors.get(f);
          final fg = bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
          return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
            child: Text(f, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500)));
        }).toList()),
      ]),
    );
  }

  /// 赏味期横幅：颜色随阶段变化，一眼看出这支豆子现在该不该冲。
  Widget _freshnessBanner(Freshness fresh) {
    final color = fresh.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(fresh.icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    fresh.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${fresh.profileName} · 烘焙 ${fresh.daysSinceRoast} 天',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  fresh.hint,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
      Expanded(child: Text(value)),
    ]),
  );
}
