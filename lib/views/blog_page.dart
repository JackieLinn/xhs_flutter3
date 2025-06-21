import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/views/homepage.dart' show Blog;

class BlogPage extends StatefulWidget {
  final String authorName;
  final String authorAvatar;
  final List<String> imageUrls;
  final String title;
  final String content;
  final int blogId;

  const BlogPage({
    Key? key,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrls,
    required this.title,
    required this.content,
    required this.blogId,
  }) : super(key: key);

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();

  int _currentPage = 0;
  List<Map<String, dynamic>> comments = [];
  int likes = 0;
  bool isLiked = false;
  Blog? blog;

  @override
  void initState() {
    super.initState();
    recordVisit(); // 新增：记录浏览历史
    fetchComments();
    fetchLikeStatus();
  }

  Future<void> recordVisit() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) return;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = int.parse(obj['id'].toString());

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      await ApiService.postApi('/auth/history/upload', data: {
        "uid": uid,
        "blogId": widget.blogId,
        "createTime": formattedDate,
      });

    } catch (e) {
      debugPrint('记录浏览失败: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) return;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'];
      final response = await ApiService.getApi(
        '/auth/comments/bid',
        queryParameters: {'blog_id': widget.blogId.toString(), 'uid': uid.toString()},
      );
      setState(() {
        comments = (response as List)
            .map((e) => {
          'id': e['id'],
          'avatar': e['user']?['avatar']?.toString() ?? 'https://i.pravatar.cc/40',
          'name': e['user']?['username']?.toString() ?? '匿名用户',
          'text': e['content']?.toString() ?? '',
          'createTime': e['createTime']?.toString() ?? '',
          'likes': e['likes'] ?? 0,
          'liked': e['liked'] ?? false,
        })
            .toList();
      });
    } catch (e) {
      debugPrint('加载评论失败：$e');
    }
  }

  Future<void> fetchLikeStatus() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('未登录');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'];
      // 获取博客详情，带uid
      final blogDetail = await ApiService.getApi('/auth/blogs/${widget.blogId}', queryParameters: {'uid': uid.toString()});
      setState(() {
        blog = Blog.fromJson(blogDetail);
        isLiked = blog!.liked;
      });
    } catch (e) {
      debugPrint('获取博客详情失败: $e');
    }
  }

  Future<void> toggleLike() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('未登录');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'];
      if (blog!.liked) {
        await ApiService.postVoid('/auth/blogs/deleteLike/${widget.blogId}?uid=$uid');
        setState(() {
          blog!.liked = false;
          blog!.likes = (blog!.likes > 0) ? blog!.likes - 1 : 0;
        });
      } else {
        await ApiService.postVoid('/auth/blogs/addLike/${widget.blogId}?uid=$uid');
        setState(() {
          blog!.liked = true;
          blog!.likes += 1;
        });
      }
    } catch (e) {
      debugPrint('点赞操作失败: $e');
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('未登录');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = obj['id'];
      if (blog!.favorited == true) {
        await ApiService.postVoid('/auth/blogs/deleteFavorite/${blog!.id}?uid=$uid');
        setState(() {
          blog!.favorited = false;
        });
      } else {
        await ApiService.postVoid('/auth/blogs/addFavorite/${blog!.id}?uid=$uid');
        setState(() {
          blog!.favorited = true;
        });
      }
    } catch (e) {
      debugPrint('收藏操作失败: $e');
    }
  }

  Future<void> submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final raw = await _storage.read(key: 'access_token');
      if (raw == null) throw Exception('未登录用户无法评论');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final uid = int.parse(obj['id'].toString());

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      await ApiService.postApi('/auth/comments/upload', data: {
        "uid": uid,
        "blogId": widget.blogId,
        "content": text,
        "likes": 0,
        "createTime": formattedDate,
      });

      _commentController.clear();
      await fetchComments();
    } catch (e) {
      debugPrint('评论提交失败：$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评论提交失败：$e')),
      );
    }
  }

  Future<void> _toggleCommentLike(Map<String, dynamic> comment) async {
    final raw = await _storage.read(key: 'access_token');
    if (raw == null) return;
    final obj = jsonDecode(raw) as Map<String, dynamic>;
    final uid = obj['id'];
    if (comment['liked'] == true) {
      await ApiService.postVoid('/auth/comments/deleteLike/${comment['id']}?uid=$uid');
      setState(() {
        comment['liked'] = false;
        comment['likes'] = (comment['likes'] ?? 1) - 1;
      });
    } else {
      await ApiService.postVoid('/auth/comments/addLike/${comment['id']}?uid=$uid');
      setState(() {
        comment['liked'] = true;
        comment['likes'] = (comment['likes'] ?? 0) + 1;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final auth = await ApiService.getAuthObject();
      final currentUid = auth['id'].toString();
      final targetUid = blog!.uid.toString();
      
      if (blog!.followed) {
        // 取消关注
        await ApiService.unfollowUser(currentUid, targetUid);
        setState(() {
          blog!.followed = false;
        });
      } else {
        // 关注
        await ApiService.followUser(currentUid, targetUid);
        setState(() {
          blog!.followed = true;
        });
      }
      
      // 通知mepage刷新用户信息
      _notifyUserInfoUpdate();
    } catch (e) {
      debugPrint('关注操作失败: $e');
      if (mounted) {
        String errorMessage = '操作失败';
        if (e.toString().contains('已经关注过了')) {
          errorMessage = '已经关注过了';
          setState(() {
            blog!.followed = true;
          });
        } else if (e.toString().contains('取消关注成功')) {
          errorMessage = '取消关注成功';
          setState(() {
            blog!.followed = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void _notifyUserInfoUpdate() {
    // 简单的刷新通知，当用户返回mepage时会自动刷新
    // 这里不需要复杂的实现，因为mepage会在页面重新获得焦点时刷新
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (blog == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'blogId': blog!.id,
          'liked': blog!.liked,
          'likes': blog!.likes,
          'favorited': blog!.favorited,
          'followed': blog!.followed,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          leading: const BackButton(color: Colors.black),
          title: Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.authorAvatar)),
              const SizedBox(width: 8),
              Text(widget.authorName, style: const TextStyle(color: Colors.black)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _toggleFollow,
              child: Text(
                blog!.followed ? '已关注' : '关注',
                style: TextStyle(
                  color: blog!.followed ? Colors.grey : Colors.red,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.share, color: Colors.black54), onPressed: () {}),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              top: true,
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  if (widget.imageUrls.isNotEmpty) ...[
                    AspectRatio(
                      aspectRatio: 1,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.imageUrls.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(widget.imageUrls[index],
                              fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imageUrls.length,
                            (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 8 : 6,
                          height: _currentPage == i ? 8 : 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i ? Colors.red : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(widget.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('${comments.length} 条评论',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ...comments.map((c) => ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(c['avatar']!)),
                    title: Text(c['name']!),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['text']!),
                        const SizedBox(height: 4),
                        Text(
                          c['createTime'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            c['liked'] == true ? Icons.favorite : Icons.favorite_border,
                            color: c['liked'] == true ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _toggleCommentLike(c),
                        ),
                        Text('${c['likes']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.authorAvatar)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '写评论…',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        blog!.favorited == true ? Icons.bookmark : Icons.bookmark_border,
                        color: blog!.favorited == true ? Colors.orange : Colors.grey,
                      ),
                      onPressed: toggleFavorite,
                    ),
                    IconButton(
                      icon: Icon(
                        blog!.liked ? Icons.favorite : Icons.favorite_border,
                        color: blog!.liked ? Colors.red : Colors.grey,
                      ),
                      onPressed: toggleLike,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: submitComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
