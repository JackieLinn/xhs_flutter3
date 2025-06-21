import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/components/side-drawer.dart';
import 'package:xhs/components/tweetcard.dart';
import 'package:xhs/views/searchpage.dart';
import 'package:xhs/views/blog_page.dart';
import 'package:xhs/services/api_service.dart';

/// 博客数据模型
class Blog {
  final int id;
  final int uid;
  final String title;
  final String content;
  int likes;
  final bool draft;
  final bool isVideo;
  final String authorName;
  final String authorAvatar;
  final List<String> imageUrls;
  final String videoUrl;
  bool liked;
  bool favorited;
  bool followed;

  Blog({
    required this.id,
    required this.uid,
    required this.title,
    required this.content,
    required this.likes,
    required this.draft,
    required this.isVideo,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrls,
    required this.videoUrl,
    required this.liked,
    required this.favorited,
    required this.followed,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>?) ?? [];
    return Blog(
      id: json['id'] as int,
      uid: json['uid'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      draft: json['draft'] as bool? ?? false,
      isVideo: json['is_video'] as bool? ?? false,
      authorName: user?['username'] as String? ?? '匿名',
      authorAvatar: user?['avatar'] as String? ?? '',
      imageUrls: images.map((e) => e['url'] as String).toList(),
      videoUrl: json['videoUrl'] as String? ?? '',
      liked: json['liked'] as bool? ?? false,
      favorited: json['favorited'] as bool? ?? false,
      followed: json['followed'] as bool? ?? false,
    );
  }
}

class Page1 extends StatefulWidget {
  final bool shouldRefresh;
  
  const Page1({Key? key, this.shouldRefresh = false}) : super(key: key);

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  late Future<List<Blog>> _futureBlogs;
  late Future<List<Blog>> _futureFollowingBlogs;
  static bool _hasRefreshed = false; // 静态变量跟踪是否已刷新

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _initFutures();
  }

  Future<void> _initFutures() async {
    final auth = await ApiService.getAuthObject();
    final uid = auth['id'].toString();
    setState(() {
      _futureBlogs = fetchRandomBlogs(page: 1, size: 10, uid: uid);
      _futureFollowingBlogs = fetchFollowingBlogs(uid: uid);
    });
  }

  @override
  void didUpdateWidget(Page1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldRefresh && !oldWidget.shouldRefresh) {
      _initFutures();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['refresh'] == true && !_hasRefreshed) {
      _hasRefreshed = true;
      _initFutures();
      Future.delayed(const Duration(milliseconds: 100), () {
        _hasRefreshed = false;
      });
    }
  }

  /// 获取推荐博客
  Future<List<Blog>> fetchRandomBlogs({required int page, required int size, required String uid}) async {
    final data = await ApiService.getApi(
      '/auth/blogs/random',
      queryParameters: {'page': page.toString(), 'size': size.toString(), 'uid': uid},
    );
    return (data as List).map((e) => Blog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取已关注用户的博客
  Future<List<Blog>> fetchFollowingBlogs({required String uid}) async {
    final auth = await ApiService.getAuthObject();
    final currentUid = auth['id'].toString();
      final data = await ApiService.getApi(
        '/auth/blogs/following',
      queryParameters: {'uid': uid, 'currentUid': currentUid},
      );
      return (data as List).map((e) => Blog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 重用的 blog 列表 UI 构建器
  Widget buildBlogGrid(List<Blog> blogs) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return TweetCard(
          imageUrl: blog.imageUrls.isNotEmpty ? blog.imageUrls.first : '',
          title: blog.title,
          avatarUrl: blog.authorAvatar,
          username: blog.authorName,
          likes: blog.likes,
          liked: blog.liked,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlogPage(
                  blogId: blog.id,
                  authorName: blog.authorName,
                  authorAvatar: blog.authorAvatar,
                  imageUrls: blog.imageUrls,
                  title: blog.title,
                  content: blog.content,
                ),
              ),
            );
            if (result != null && result is Map) {
              // 重新拉取数据
              final auth = await ApiService.getAuthObject();
              final uid = auth['id'].toString();
              setState(() {
                _futureBlogs = fetchRandomBlogs(page: 1, size: 10, uid: uid);
                _futureFollowingBlogs = fetchFollowingBlogs(uid: uid);
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const SideDrawer(),
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
                  tabs: const [
                    Tab(text: "关注"),
                    Tab(text: "发现"),
                    Tab(text: "昆明"),
                  ],
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
          FutureBuilder<List<Blog>>(
            future: _futureFollowingBlogs,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('加载失败：${snapshot.error}'));
              }
              final blogs = snapshot.data!;
              return blogs.isEmpty
                  ? const Center(child: Text("暂无关注内容"))
                  : buildBlogGrid(blogs);
            },
          ),
          FutureBuilder<List<Blog>>(
            future: _futureBlogs,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('加载失败：${snapshot.error}'));
              }
              final blogs = snapshot.data!;
              return buildBlogGrid(blogs);
            },
          ),
          const Center(child: Text("昆明内容", style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
