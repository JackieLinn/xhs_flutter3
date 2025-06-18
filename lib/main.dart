import 'package:flutter/material.dart';
import 'package:xhs/views/mepage.dart';
import 'package:xhs/views/write_blog_page.dart';

import 'views/homepage.dart';
import 'views/hotpage.dart'; // Page2
import 'views/page3.dart';
import 'views/shop.dart';
import 'views/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Footer Navigation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: '/',  // 初始路由为登录页
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)
              ?.settings
              .arguments as Map<String, dynamic>?;
          final initialIndex = (args != null && args['initialIndex'] is int)
              ? args['initialIndex'] as int
              : 0;
          return MyHomePage(
            title: 'Ssexhs',
            initialIndex: initialIndex,
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.initialIndex = 0});
  final String title;
  final int initialIndex;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;
  bool _shouldRefresh = false;
  static bool _hasRefreshed = false; // 静态变量跟踪是否已刷新

  final GlobalKey<Page2State> _page2Key =
      GlobalKey<Page2State>(); // 新增 GlobalKey
  late Page2 _page2; // 保存Page2实例

  @override
  void initState() {
    super.initState();
    _page2 = Page2(key: _page2Key); // 绑定 key
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查是否需要刷新
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['refresh'] == true && !_hasRefreshed) {
      _hasRefreshed = true; // 标记已刷新
      // 设置刷新标志并切换到首页
      setState(() {
        _shouldRefresh = true;
        _selectedIndex = 0;
      });
      
      // 延迟重置刷新标志
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _shouldRefresh = false;
            _hasRefreshed = false; // 重置刷新标记
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Page1(key: const ValueKey('page1'), shouldRefresh: _shouldRefresh),
      _page2,
      WriteBlogPage(),
      const ShopPage(),
      const MyPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        height: 70,
        color: _selectedIndex == 1 ? Colors.black : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem("首页", 0),
            _buildBottomNavItem("热门", 1),
            _buildPlusButton(),
            _buildBottomNavItem("购物", 3),
            _buildBottomNavItem("我", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedIndex == 1) {
              _page2Key.currentState?.pauseVideo(); // 调用 Page2 的 pauseVideo
            }
            _selectedIndex = index;
          });
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 18 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  _selectedIndex == 1
                      ? Colors.white
                      : (isSelected ? Colors.black : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusButton() {
    return SizedBox(
      width: 55,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedIndex == 1) {
              _page2Key.currentState?.pauseVideo(); // 同样处理
            }
            _selectedIndex = 2;
          });
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 25, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
