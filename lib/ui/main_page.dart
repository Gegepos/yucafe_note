import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_tab_controller.dart';
import '../controllers/user_controller.dart';
import '../utils/error_utils.dart';
import '../utils/image_utils.dart';
import '../app/routes.dart';
import 'dashboard/dashboard_page.dart';
import 'museum/museum_page.dart';
import 'notes/note_list_page.dart';
import 'profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainTabController _tab = Get.find<MainTabController>();

  final _pages = const [
    DashboardPage(),
    MuseumPage(),
    NoteListPage(),
    ProfilePage(),
  ];

  final _titles = const ['控制中枢', '博物馆', '笔记', '我的'];

  /// 新增页成功时回传 'created'，这里负责切换 tab 并弹提示
  /// （提示在新增页里弹会被紧随的 pop 一起带走）。
  Future<void> _showAddMenu() async {
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 80,
        MediaQuery.of(context).size.height - 120,
        MediaQuery.of(context).size.width / 2 + 80,
        MediaQuery.of(context).size.height - 60,
      ),
      items: [
        const PopupMenuItem(
          value: 'bean',
          child: ListTile(
            leading: Icon(Icons.coffee),
            title: Text('新增咖啡豆'),
          ),
        ),
        const PopupMenuItem(
          value: 'note',
          child: ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('新增笔记'),
          ),
        ),
      ],
    );

    if (!mounted) return;

    if (value == 'bean') {
      final result = await Get.toNamed(AppRoutes.addBean);
      if (!mounted) return;
      if (result == 'created') {
        _tab.go(1);
        ErrorUtils.showSuccess('咖啡豆新增成功');
      }
    } else if (value == 'note') {
      final result = await Get.toNamed(AppRoutes.addNote);
      if (!mounted) return;
      if (result == 'created') {
        _tab.go(2);
        ErrorUtils.showSuccess('笔记新增成功');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = _tab.index.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(_titles[index]),
          leading: index != 3
              ? GestureDetector(
                  onTap: () => _tab.go(3),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Obx(() {
                      final user = Get.find<UserController>().profile.value;
                      final avatar = ImageUtils.avatarProvider(user?.avatar);
                      return CircleAvatar(
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      );
                    }),
                  ),
                )
              : null,
        ),
        body: _pages[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            _tab.go(i);
            if (i == 3) Get.find<UserController>().fetchProfile();
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '控制中枢'),
            BottomNavigationBarItem(icon: Icon(Icons.museum), label: '博物馆'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: '笔记'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: _showAddMenu,
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
