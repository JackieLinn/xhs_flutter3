import 'package:flutter/material.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int randomAvatarIndex = DateTime.now().millisecondsSinceEpoch % 70 + 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部背景区域（整体高度收缩）
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.indigo.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppBar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.menu, color: Colors.white),
                    Row(
                      children: [
                        Icon(Icons.brush, color: Colors.white),
                        const SizedBox(width: 16),
                        Icon(Icons.qr_code, color: Colors.white),
                        const SizedBox(width: 16),
                        Icon(Icons.share, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 头像 + 昵称/小红书号
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=$randomAvatarIndex'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('小红书用户', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('小红书号：12345678', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 简介
                const Text('简介：爱旅行，爱美食', style: TextStyle(color: Colors.white, fontSize: 13)),

                const SizedBox(height: 6),

                // 性别
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.female, size: 14, color: Colors.pink),
                      SizedBox(width: 4),
                      Text('女生', style: TextStyle(color: Colors.black87, fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 关注 粉丝 获赞 + 右侧按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text('关注 123', style: TextStyle(color: Colors.white, fontSize: 13)),
                        SizedBox(width: 12),
                        Text('粉丝 456', style: TextStyle(color: Colors.white, fontSize: 13)),
                        SizedBox(width: 12),
                        Text('获赞 789', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('编辑资料', style: TextStyle(color: Colors.black, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.settings, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              // 渐变背景 + 圆角
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Container(
                  height: 50, // 控制高度，适配视觉
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.indigo.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // TabBar
              Container(
                height: 50, // 同样的高度
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [
                    Tab(text: '笔记'),
                    Tab(text: '收藏'),
                    Tab(text: '赞过'),
                  ],
                ),
              ),
            ],
          ),


          Expanded(
            child: Container(
              color: const Color(0xFFEEEEEE), // #eee 背景
              child: TabBarView(
                controller: _tabController,
                children: const [
                  Center(child: Text('这里是笔记内容')),
                  Center(child: Text('这里是收藏内容')),
                  Center(child: Text('这里是赞过内容')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
