import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xhs/services/api_service.dart';
import 'package:xhs/views/homepage.dart' show Blog;

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => Page2State();
}

class Page2State extends State<Page2> {
  late Future<List<Blog>> _futureVideoBlogs;
  VideoPlayerController? _currentController;
  int _currentPage = 0;
  final Set<int> likedBlogIds = {};

  @override
  void initState() {
    super.initState();
    _futureVideoBlogs = fetchVideoBlogs();
  }

  Future<List<Blog>> fetchVideoBlogs() async {
    final auth = await ApiService.getAuthObject();
    final uid = auth['id'].toString();
    final data = await ApiService.getApi('/auth/blogs/random/video', queryParameters: {'uid': uid});
    return (data as List).map((e) => Blog.fromJson(e as Map<String, dynamic>)).toList();
  }

  void _initializeController(String videoUrl) async {
    _currentController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(1.0);
    controller.play();
    setState(() {
      _currentController = controller;
    });
  }

  void pauseVideo() {
    _currentController?.pause();
  }

  void _showCommentsSheet(BuildContext context, int blogId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _CommentsSheet(blogId: blogId);
      },
    );
  }

  Future<void> _toggleLike(Blog blog) async {
    try {
      final auth = await ApiService.getAuthObject();
      final uid = int.parse(auth['id'].toString());
      if (likedBlogIds.contains(blog.id)) {
        await ApiService.postVoid(
          '/auth/blogs/deleteLike/${blog.id}?uid=$uid',
        );
        setState(() {
          likedBlogIds.remove(blog.id);
          blog.likes -= 1;
        });
      } else {
        await ApiService.postVoid(
          '/auth/blogs/addLike/${blog.id}?uid=$uid',
        );
        setState(() {
          likedBlogIds.add(blog.id);
          blog.likes += 1;
        });
      }
    } catch (e) {
      debugPrint('点赞操作失败: $e');
    }
  }

  Future<void> _toggleFollow(Blog blog) async {
    try {
      final auth = await ApiService.getAuthObject();
      final currentUid = auth['id'].toString();
      final targetUid = blog.uid.toString();
      
      if (blog.followed) {
        // 取消关注
        await ApiService.unfollowUser(currentUid, targetUid);
        setState(() {
          blog.followed = false;
        });
      } else {
        // 关注
        await ApiService.followUser(currentUid, targetUid);
        setState(() {
          blog.followed = true;
        });
      }
      
      // 通知需要刷新用户信息
      _notifyUserInfoUpdate();
    } catch (e) {
      debugPrint('关注操作失败: $e');
      if (mounted) {
        String errorMessage = '操作失败';
        if (e.toString().contains('已经关注过了')) {
          errorMessage = '已经关注过了';
          // 如果已经关注过了，更新本地状态
          setState(() {
            blog.followed = true;
          });
        } else if (e.toString().contains('取消关注成功')) {
          errorMessage = '取消关注成功';
          setState(() {
            blog.followed = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void _notifyUserInfoUpdate() {
    // 通过全局变量或其他方式通知mepage刷新
    // 这里可以设置一个全局标志，让mepage知道需要刷新
  }

  @override
  void dispose() {
    _currentController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Blog>>(
        future: _futureVideoBlogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败： {snapshot.error}', style: TextStyle(color: Colors.white)));
          }
          final blogs = snapshot.data!;
          if (blogs.isEmpty) {
            return const Center(child: Text('暂无视频内容', style: TextStyle(color: Colors.white)));
          }
          return PageView.builder(
        scrollDirection: Axis.vertical,
            itemCount: blogs.length,
        onPageChanged: (index) {
              final blog = blogs[index];
              final videoUrl = blog.videoUrl.isNotEmpty
                  ? blog.videoUrl
                  : (blog.imageUrls.isNotEmpty ? blog.imageUrls.first : null);
              if (videoUrl != null) {
                _initializeController(videoUrl);
              }
          _currentPage = index;
        },
        itemBuilder: (context, index) {
              final blog = blogs[index];
          final isCurrent = index == _currentPage;
              final videoUrl = blog.videoUrl.isNotEmpty
                  ? blog.videoUrl
                  : (blog.imageUrls.isNotEmpty ? blog.imageUrls.first : null);
              if (isCurrent && videoUrl != null && (_currentController == null || !_currentController!.value.isInitialized)) {
                _initializeController(videoUrl);
              }
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentController != null) {
                    if (_currentController!.value.isPlaying) {
                      _currentController!.pause();
                    } else {
                      _currentController!.play();
                    }
                    setState(() {});
                  }
                },
                child: Center(
                  child: isCurrent && _currentController != null && _currentController!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: _currentController!.value.aspectRatio,
                    child: VideoPlayer(_currentController!),
                  )
                      : const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                              backgroundImage: NetworkImage(blog.authorAvatar),
                        ),
                        const SizedBox(width: 8),
                        Text(
                              '@${blog.authorName}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _toggleFollow(blog),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: blog.followed ? Colors.grey : Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              blog.followed ? '已关注' : '关注',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                        Text(
                          blog.title,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    IconButton(
                          icon: Icon(
                            blog.liked ? Icons.favorite : Icons.favorite_border,
                            color: blog.liked ? Colors.red : Colors.white,
                          ),
                          onPressed: () async {
                            await _toggleLike(blog);
                            setState(() {
                              blog.liked = !blog.liked;
                            });
                          },
                    ),
                        Text('${blog.likes}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.white),
                          onPressed: () {
                            _showCommentsSheet(context, blog.id);
                          },
                    ),
                        const Text('评论', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                          icon: Icon(
                            blog.favorited == true ? Icons.bookmark : Icons.bookmark_border,
                            color: blog.favorited == true ? Colors.orange : Colors.white,
                          ),
                          onPressed: () async {
                            final auth = await ApiService.getAuthObject();
                            final uid = int.parse(auth['id'].toString());
                            if (blog.favorited == true) {
                              await ApiService.postVoid('/auth/blogs/deleteFavorite/${blog.id}?uid=$uid');
                              setState(() {
                                blog.favorited = false;
                              });
                            } else {
                              await ApiService.postVoid('/auth/blogs/addFavorite/${blog.id}?uid=$uid');
                              setState(() {
                                blog.favorited = true;
                              });
                            }
                          },
                    ),
                    const Text('收藏', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (isCurrent && _currentController != null && _currentController!.value.isInitialized)
                Center(
                  child: _currentController!.value.isPlaying
                      ? const SizedBox()
                      : const Icon(Icons.play_arrow, color: Colors.white, size: 80),
                ),
            ],
              );
            },
          );
        },
      ),
    );
  }
}

// 评论弹窗组件
class _CommentsSheet extends StatefulWidget {
  final int blogId;
  const _CommentsSheet({required this.blogId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    setState(() => _loading = true);
    try {
      final auth = await ApiService.getAuthObject();
      final uid = int.parse(auth['id'].toString());
      final data = await ApiService.getApi(
        '/auth/comments/bid',
        queryParameters: {'blog_id': widget.blogId.toString(), 'uid': uid.toString()},
      );
      setState(() {
        comments = (data as List).map((e) => {
          'id': e['id'],
          'avatar': e['user']?['avatar']?.toString() ?? 'https://i.pravatar.cc/40',
          'name': e['user']?['username']?.toString() ?? '匿名用户',
          'text': e['content']?.toString() ?? '',
          'createTime': e['createTime']?.toString() ?? '',
          'likes': e['likes'] ?? 0,
          'liked': e['liked'] ?? false,
        }).toList();
      });
    } catch (e) {
      debugPrint('加载评论失败: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      // 获取当前用户id
      final auth = await ApiService.getAuthObject();
      final uid = int.parse(auth['id'].toString());
      await ApiService.postApi('/auth/comments/upload', data: {
        'uid': uid,
        'blogId': widget.blogId,
        'content': text,
        'likes': 0,
        'createTime': DateTime.now().toIso8601String(),
      });
      _controller.clear();
      await fetchComments();
    } catch (e) {
      debugPrint('评论提交失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评论提交失败: $e')),
      );
    }
  }

  Future<void> _toggleCommentLike(Map<String, dynamic> comment) async {
    final auth = await ApiService.getAuthObject();
    final uid = int.parse(auth['id'].toString());
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 6,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Text('评论区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? const Center(child: Text('暂无评论'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, index) => ListTile(
                            leading: CircleAvatar(backgroundImage: NetworkImage(comments[index]['avatar']!)),
                            title: Row(
                              children: [
                                Text(comments[index]['name']!),
                                const SizedBox(width: 8),
                                Text(
                                  _formatCommentTime(comments[index]['createTime']),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: Text(comments[index]['text']!),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    comments[index]['liked'] == true ? Icons.favorite : Icons.favorite_border,
                                    color: comments[index]['liked'] == true ? Colors.red : Colors.grey,
                                    size: 18,
                                  ),
                                  onPressed: () => _toggleCommentLike(comments[index]),
                                ),
                                Text('${comments[index]['likes']}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
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
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: submitComment,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// 在 _CommentsSheetState 外部添加格式化时间方法
String _formatCommentTime(String timeStr) {
  if (timeStr.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(timeStr);
    if (dt == null) return timeStr;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return timeStr;
  }
}
