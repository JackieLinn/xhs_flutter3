import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/components/side-drawer.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/components/tweetcard.dart';
import 'package:xhs/views/blog_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Store the user's blogs
  List<Map<String, dynamic>> blogs = [];
  List<Map<String, dynamic>> likedBlogs = [];
  List<Map<String, dynamic>> favoriteBlogs = [];

  // User info variables
  String username = '';
  String avatarUrl = '';
  int followCount = 0;
  int fansCount = 0;
  int likesCount = 0;
  int sex = 0; // 0: Unknown, 1: Male, 2: Female
  String xhsId = ''; // Xiaohongshu ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserInfo(); // Fetch user info when the page is initialized
    fetchBlogs(); // Fetch blogs when the page is initialized
  }

  // Fetch the user information from the API
  Future<void> fetchUserInfo() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('User is not logged in');

      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'].toString(); // Get the uid from the token

      final response = await ApiService.getApi('/api/account/get-account-by-userId', queryParameters: {'uid': uid});
      setState(() {
        username = response['username'];
        avatarUrl = response['avatar'];
        followCount = response['follow'];
        fansCount = response['fans'];
        likesCount = response['likes'];
        sex = response['sex'];
        xhsId = response['id'].toString(); // Use user id as Xiaohongshu ID
      });
    } catch (e) {
      debugPrint('Failed to fetch user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch user info')));
    }
  }

  // Fetch the blogs using the API
  Future<void> fetchBlogs() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('User is not logged in');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'].toString();
      // 获取自己的博客
      final response = await ApiService.getApi('/auth/blogs/uid', queryParameters: {'uid': uid, 'currentUid': uid});
      setState(() {
        blogs = (response as List).map((e) => {
          'id': e['id'],
          'title': e['title'],
          'content': e['content'],
          'createdAt': e['createTime'],
          'likes': e['likes'] ?? 0,
          'imageUrl': (e['images'] != null && e['images'].isNotEmpty)
              ? e['images'][0]['url']
              : '',
          'liked': e['liked'] is bool ? e['liked'] : e['liked'] == 'true',
        }).toList();
      });
      // 获取点赞过的博客
      final likedResp = await ApiService.getApi('/auth/blogs/like', queryParameters: {'uid': uid});
      setState(() {
        likedBlogs = (likedResp as List).map((e) => {
          'id': e['id'],
          'title': e['title'],
          'content': e['content'],
          'createdAt': e['createTime'],
          'likes': e['likes'] ?? 0,
          'imageUrl': (e['images'] != null && e['images'].isNotEmpty)
              ? e['images'][0]['url']
              : '',
          'authorAvatar': e['user']?['avatar'] ?? '',
          'authorName': e['user']?['username'] ?? '',
          'liked': e['liked'] is bool ? e['liked'] : e['liked'] == 'true',
        }).toList();
      });
      // 获取收藏的博客
      final favoriteResp = await ApiService.getApi('/auth/blogs/favorite', queryParameters: {'uid': uid});
      print(favoriteResp);
      setState(() {
        favoriteBlogs = (favoriteResp as List).map((e) => {
          'id': e['id'],
          'title': e['title'],
          'content': e['content'],
          'createdAt': e['createTime'],
          'likes': e['likes'] ?? 0,
          'imageUrl': (e['images'] != null && e['images'].isNotEmpty)
              ? e['images'][0]['url']
              : '',
          'authorAvatar': (e['user'] != null && e['user']['avatar'] != null && e['user']['avatar'].toString().isNotEmpty)
              ? e['user']['avatar']
              : (avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=1'),
          'authorName': e['user']?['username'] ?? '',
          'liked': e['liked'] is bool ? e['liked'] : e['liked'] == 'true',
          'favorited': e['favorited'] is bool ? e['favorited'] : e['favorited'] == 'true',
        }).toList();
      });
    } catch (e) {
      debugPrint('Failed to fetch blogs: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch blogs')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideDrawer(),
      body: Column(
        children: [
          // Top background section
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
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.brush, color: Colors.white),
                        SizedBox(width: 16),
                        Icon(Icons.qr_code, color: Colors.white),
                        SizedBox(width: 16),
                        Icon(Icons.share, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Avatar + Name / Xiaohongshu ID
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(avatarUrl.isEmpty ? 'https://i.pravatar.cc/150?img=1' : avatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username.isEmpty ? '小红书用户' : username,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '小红书号：$xhsId',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('简介：爱旅行，爱美食', style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 6),
                // Gender
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sex == 1 ? Icons.male : (sex == 2 ? Icons.female : Icons.transgender),
                        size: 14,
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sex == 1 ? '男' : (sex == 2 ? '女' : '未知'),
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Followers, Fans, Likes + Right button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('关注 $followCount', style: TextStyle(color: Colors.white, fontSize: 13)),
                        SizedBox(width: 12),
                        Text('粉丝 $fansCount', style: TextStyle(color: Colors.white, fontSize: 13)),
                        SizedBox(width: 12),
                        Text('获赞 $likesCount', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
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
          // TabBar section
          Stack(
            children: [
              // Gradient background + Rounded Corners
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                child: Container(
                  height: 50,
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
                height: 50,
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [Tab(text: '笔记'), Tab(text: '收藏'), Tab(text: '赞过')],
                ),
              ),
            ],
          ),
          // TabBarView for displaying content
          Expanded(
            child: Container(
              color: const Color(0xFFEEEEEE),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Notes Tab - Updated for 2-column layout
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two columns
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.65, // 与 homepage 保持一致
                    ),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      return TweetCard(
                        imageUrl: blogs[index]['imageUrl'] ?? '',
                        title: blogs[index]['title'] ?? '',
                        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=1',
                        username: username.isNotEmpty ? username : '小红书用户',
                        likes: blogs[index]['likes'] ?? 0,
                        liked: false,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlogPage(
                                blogId: blogs[index]['id'],
                                authorName: username.isNotEmpty ? username : '小红书用户',
                                authorAvatar: avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=1',
                                imageUrls: blogs[index]['imageUrl'] != '' ? [blogs[index]['imageUrl']] : [],
                                title: blogs[index]['title'] ?? '',
                                content: blogs[index]['content'] ?? '',
                              ),
                            ),
                          );
                          await fetchBlogs();
                        },
                      );
                    },
                  ),
                  // 收藏Tab：展示收藏的博客
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: favoriteBlogs.length,
                    itemBuilder: (context, index) {
                      return TweetCard(
                        imageUrl: favoriteBlogs[index]['imageUrl'] ?? '',
                        title: favoriteBlogs[index]['title'] ?? '',
                        avatarUrl: (favoriteBlogs[index]['authorAvatar'] != null && favoriteBlogs[index]['authorAvatar'].toString().isNotEmpty)
                            ? favoriteBlogs[index]['authorAvatar']
                            : (avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=1'),
                        username: (favoriteBlogs[index]['authorName'] != null && favoriteBlogs[index]['authorName'].toString().isNotEmpty)
                            ? favoriteBlogs[index]['authorName']
                            : (username.isNotEmpty ? username : '小红书用户'),
                        likes: favoriteBlogs[index]['likes'] ?? 0,
                        liked: favoriteBlogs[index]['liked'] ?? false,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlogPage(
                                blogId: favoriteBlogs[index]['id'],
                                authorName: (favoriteBlogs[index]['authorName'] != null && favoriteBlogs[index]['authorName'].toString().isNotEmpty)
                                    ? favoriteBlogs[index]['authorName']
                                    : (username.isNotEmpty ? username : '小红书用户'),
                                authorAvatar: (favoriteBlogs[index]['authorAvatar'] != null && favoriteBlogs[index]['authorAvatar'].toString().isNotEmpty)
                                    ? favoriteBlogs[index]['authorAvatar']
                                    : (avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=1'),
                                imageUrls: favoriteBlogs[index]['imageUrl'] != '' ? [favoriteBlogs[index]['imageUrl']] : [],
                                title: favoriteBlogs[index]['title'] ?? '',
                                content: favoriteBlogs[index]['content'] ?? '',
                              ),
                            ),
                          );
                          await fetchBlogs();
                        },
                      );
                    },
                  ),
                  // 赞过Tab：展示点赞过的博客
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: likedBlogs.length,
                    itemBuilder: (context, index) {
                      return TweetCard(
                        imageUrl: likedBlogs[index]['imageUrl'] ?? '',
                        title: likedBlogs[index]['title'] ?? '',
                        avatarUrl: likedBlogs[index]['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
                        username: likedBlogs[index]['authorName'] ?? '小红书用户',
                        likes: likedBlogs[index]['likes'] ?? 0,
                        liked: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlogPage(
                                blogId: likedBlogs[index]['id'],
                                authorName: likedBlogs[index]['authorName'] ?? '小红书用户',
                                authorAvatar: likedBlogs[index]['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
                                imageUrls: likedBlogs[index]['imageUrl'] != '' ? [likedBlogs[index]['imageUrl']] : [],
                                title: likedBlogs[index]['title'] ?? '',
                                content: likedBlogs[index]['content'] ?? '',
                              ),
                            ),
                          );
                          await fetchBlogs();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
