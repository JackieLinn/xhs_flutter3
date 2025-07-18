import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/views/friends_page.dart';
import 'package:xhs/views/comments_page.dart';
import 'package:xhs/views/history_page.dart';
import 'package:xhs/views/orders_page.dart';
import 'package:xhs/views/cart_page.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final _storage = const FlutterSecureStorage(); // ← 实例化
    const bottomBarHeight = kBottomNavigationBarHeight;
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.only(top: 24.0, bottom: bottomBarHeight),
        children: [
          // 第一组：发现好友、创作者中心
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('发现好友'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('创作者中心'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转创作者中心页面
                  },
                ),
              ],
            ),
          ),

          // 第二组：我的草稿、我的评论、浏览记录
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.drafts),
                  title: const Text('我的草稿'),
                  onTap: () {
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.comment),
                  title: const Text('我的评论'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CommentsPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('浏览记录'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 第三组：订单、购物车、钱包
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('订单'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('购物车'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('钱包'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转钱包页面
                  },
                ),
              ],
            ),
          ),

          // 第四组：小程序、社区公约
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.widgets),
                  title: const Text('小程序'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转小程序页面
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.eco),
                  title: const Text('社区公约'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转社区公约页面
                  },
                ),
                const Divider(height: 1),
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
              ],
            ),
          ),

          // 底部操作按钮
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: const [
                    Icon(Icons.qr_code_scanner, size: 28),
                    SizedBox(height: 4),
                    Text('扫一扫', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: const [
                    Icon(Icons.headset_mic, size: 28),
                    SizedBox(height: 4),
                    Text('帮助与客服', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: const [
                    Icon(Icons.settings, size: 28),
                    SizedBox(height: 4),
                    Text('设置', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
