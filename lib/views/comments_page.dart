import 'package:flutter/material.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/views/blog_page.dart';

class Comment {
  final String username;
  final String avatar;
  final String date;
  final String content;
  final int likes;
  final int blogId;
  final String blogTitle;
  final String blogContent;
  final List<String> blogImages;

  Comment({
    required this.username,
    required this.avatar,
    required this.date,
    required this.content,
    required this.likes,
    required this.blogId,
    required this.blogTitle,
    required this.blogContent,
    required this.blogImages,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final blog = json['blog'] ?? {};
    final images = (blog['images'] ?? []) as List<dynamic>;
    return Comment(
      username: user['username']?.toString() ?? '匿名',
      avatar: user['avatar']?.toString() ?? '',
      date: (json['createTime']?.toString() ?? '').split('T').first,
      content: json['content']?.toString() ?? '',
      likes: json['likes'] ?? 0,
      blogId: blog['id'] ?? -1,
      blogTitle: blog['title'] ?? '无标题',
      blogContent: blog['content'] ?? '',
      blogImages: images.map((e) => e['url'].toString()).toList(),
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late Future<List<Comment>> _futureComments;

  @override
  void initState() {
    super.initState();
    _futureComments = fetchMyComments();
  }

  Future<List<Comment>> fetchMyComments() async {
    final auth = await ApiService.getAuthObject();
    final uid = auth['id'].toString();
    final data = await ApiService.getApi(
      '/auth/comments/uid',
      queryParameters: {'uid': uid},
    );
    return (data as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void navigateToBlog(Comment comment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlogPage(
          blogId: comment.blogId,
          authorName: comment.username,
          authorAvatar: comment.avatar,
          title: comment.blogTitle,
          content: comment.blogContent,
          imageUrls: comment.blogImages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的评论'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: FutureBuilder<List<Comment>>(
        future: _futureComments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final comments = snapshot.data!;
          if (comments.isEmpty) {
            return const Center(child: Text("暂无评论"));
          }

          return ListView.separated(
            itemCount: comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(comment.avatar)),
                title: Text(comment.username),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.content),
                    const SizedBox(height: 4),
                    Text(comment.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: comment.blogImages.isNotEmpty
                    ? Image.network(comment.blogImages.first, width: 60, height: 60, fit: BoxFit.cover)
                    : null,
                onTap: () => navigateToBlog(comment),
              );
            },
          );
        },
      ),
    );
  }
}
