import 'package:flutter/material.dart';
import 'package:xhs/components/tweetcard.dart';
import 'detailpage.dart';

class Page1 extends StatefulWidget {
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 设置默认的选中Tab为第二个，即index: 1
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white, // AppBar整体为白色
          surfaceTintColor: Colors.transparent, // 关键！去掉Material3叠加色
          elevation: 4, // AppBar阴影
          shadowColor: Colors.grey,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Menu tapped")),
                  );
                },
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red, // 红色指示器
                  indicatorWeight: 2,
                  labelColor: Colors.black, // 选中字体黑色
                  unselectedLabelColor: Colors.grey, // 未选中字体灰色
                  labelStyle: const TextStyle(fontSize: 16),
                  unselectedLabelStyle: const TextStyle(fontSize: 16),
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: "关注"),
                    Tab(text: "发现"),
                    Tab(text: "昆明"),
                  ],
                  dividerColor: Colors.transparent, // 去掉分隔线
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Search tapped")),
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
            childAspectRatio: 0.65, // 调整卡片为更修长的比例
            children: [
              TweetCard(
                imageUrl: 'https://picsum.photos/400/200',
                title: '这是一条推文标题',
                avatarUrl: 'https://i.pravatar.cc/100',
                username: '小明',
                likes: 123,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const DetailPage(title: '这是一条推文标题'),
                  ));
                },
              ),
              TweetCard(
                imageUrl: 'https://picsum.photos/400/201',
                title: '又一条推文',
                avatarUrl: 'https://i.pravatar.cc/101',
                username: '小红',
                likes: 88,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const DetailPage(title: '又一条推文'),
                  ));
                },
              ),
              // 可以再加更多卡片
            ],
          ),
          const Center(child: Text("昆明内容", style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
