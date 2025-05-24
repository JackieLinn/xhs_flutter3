import 'package:flutter/material.dart';
import 'views/homepage.dart';
import 'views/page3.dart';
import 'views/page2.dart';

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
      home: const MyHomePage(title: 'Ssexhs'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // 页面内容
  final List<Widget> _pages = [
    Page1(), // 首页
    Page2(), // 热门
    Page3(), // +（按钮页面）
    Center(child: Text("消息", style: TextStyle(fontSize: 24))), // 消息
    Center(child: Text("我的", style: TextStyle(fontSize: 24))), // 我的
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 70, // 设置底部导航栏高度为70
        color: Colors.white, // 强制白色背景
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem("首页", 0),
            _buildBottomNavItem("热门", 1),
            _buildPlusButton(), // + 按钮
            _buildBottomNavItem("商城", 3),
            _buildBottomNavItem("我", 4),
          ],
        ),
      ),
    );
  }

  // 创建底部导航栏的按钮
  Widget _buildBottomNavItem(String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          color: Colors.white, // 保持白色背景
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSelected ? 18 : 16, // 选中变大
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey, // 选中黑色，未选中灰色
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 创建+按钮的样式
  Widget _buildPlusButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2; // +按钮对应的Tab索引
        });
      },
      child: Container(
        height: 45,
        width: 55,
        decoration: BoxDecoration(
          color: Colors.red, // 红色背景
          borderRadius: BorderRadius.circular(12), // 圆角
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 25, // 调整图标大小为25
            color: Colors.white, // 加号为白色
          ),
        ),
      ),
    );
  }
}
