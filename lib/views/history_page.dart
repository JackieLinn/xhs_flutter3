import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/components/tweetcard.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/views/blog_page.dart';

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
  bool liked;

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
    this.liked = false,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((e) => e['url'] as String)
        .toList();

    return Blog(
      id: json['id'] as int,
      uid: json['uid'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      draft: json['draft'] as bool? ?? false,
      isVideo: json['is_video'] as bool? ?? false,
      authorName: user['username'] as String? ?? '匿名',
      authorAvatar: user['avatar'] as String? ?? '',
      imageUrls: images,
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Blog>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _futureHistory = fetchHistoryBlogs();
  }

  Future<List<Blog>> fetchHistoryBlogs() async {
    final tokenRaw = await _storage.read(key: 'access_token');
    if (tokenRaw == null) throw Exception("未登录");

    final tokenObj = Map<String, dynamic>.from(await ApiService.getAuthObject());
    final uid = tokenObj['id'];

    final response = await ApiService.getApi('/auth/history/$uid');
    return (response as List)
        .map((e) => Blog.fromJson(e['blog']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览记录'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Blog>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final blogs = snapshot.data!;
          if (blogs.isEmpty) {
            return const Center(child: Text('暂无浏览记录'));
          }

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
                    setState(() {
                      blog.liked = result['liked'];
                      blog.likes = result['likes'];
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
