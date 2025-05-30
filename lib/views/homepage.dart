import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ← 新增
import 'package:xhs/components/tweetcard.dart';
import 'package:xhs/views/searchpage.dart';

import 'detailpage.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage(); // ← 实例化

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.pinkAccent),
              child: Text(
                '菜单',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('发现好友'),
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("发现好友点击")));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () async {
                // 先关闭 drawer
                Navigator.pop(context);
                // 删除本地存储的 token
                await _storage.delete(key: 'access_token');
                // 跳回登录页，并清空导航栈
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              },
            ),
            // 可以继续添加更多菜单项...
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          titleSpacing: 0,
          title: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  indicatorWeight: 2,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 16),
                  unselectedLabelStyle: const TextStyle(fontSize: 16),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: "关注"),
                    Tab(text: "发现"),
                    Tab(text: "昆明"),
                  ],
                  dividerColor: Colors.transparent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const SearchPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text("发现内容", style: TextStyle(fontSize: 24))),
          GridView.count(
            padding: const EdgeInsets.all(8),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.65,
            children: [
              TweetCard(
                imageUrl: 'https://picsum.photos/400/200',
                title: '这是一条推文标题',
                avatarUrl: 'https://i.pravatar.cc/100',
                username: '小明',
                likes: 123,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const DetailPage(title: '这是一条推文标题'),
                    ),
                  );
                },
              ),
              TweetCard(
                imageUrl: 'https://picsum.photos/400/201',
                title: '又一条推文',
                avatarUrl: 'https://i.pravatar.cc/101',
                username: '小红',
                likes: 88,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const DetailPage(title: '又一条推文'),
                    ),
                  );
                },
              ),
            ],
          ),
          const Center(child: Text("昆明内容", style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
