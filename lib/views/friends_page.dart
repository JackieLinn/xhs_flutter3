import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Future<List<dynamic>> _futureFriends;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFriends();
  }

  /// 加载当前用户ID 和 推荐好友列表
  Future<void> _loadUserIdAndFriends() async {
    final auth = await ApiService.getAuthObject(); // 获取本地存储的登录信息
    _userId = auth['id'];
    setState(() {
      _futureFriends = ApiService.getApi(
        '/api/account/random-unfollowed',
        queryParameters: {'uid': _userId!},
      ).then((data) => data as List<dynamic>);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现好友'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
        future: _futureFriends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无推荐好友'));
          }

          final users = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadUserIdAndFriends(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['avatar'] ?? ''),
                  ),
                  title: Text(user['username'] ?? '未知用户'),
                  subtitle: Text('ID: ${user['id']}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiService.postVoid(
                          '/api/follower/add',
                          data: {
                            'follower': int.parse(_userId!),
                            'uid': user['id'],
                          },
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('关注成功')),
                        );

                        setState(() {
                          users.removeAt(index);
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('关注失败：$e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('关注'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
