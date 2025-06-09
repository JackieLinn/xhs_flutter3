import 'package:flutter/material.dart';

/// 漫画日常博客详情页面，更新：图片完整显示+指示条，写评论位置调整，固定底部输入栏
class BlogPage extends StatefulWidget {
  final String authorName;
  final String authorAvatar;
  final List<String> imageUrls;
  final String title;
  final String content;

  const BlogPage({
    Key? key,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrls,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> comments = const [
    {'avatar': 'https://i.pravatar.cc/40?img=5', 'name': '一只小肥羊', 'text': '我觉得的蓝轩宁♀才是真正的高手。'},
    {'avatar': 'https://i.pravatar.cc/40?img=15', 'name': '小红薯64045E4', 'text': '你也看斗罗🤣'},
    {'avatar': 'https://i.pravatar.cc/40?img=25', 'name': '神子姐姐', 'text': '猜猜哪个是我。'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.authorAvatar),
            ),
            const SizedBox(width: 8),
            Text(widget.authorName, style: const TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('关注', style: TextStyle(color: Colors.red)),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black54),
            onPressed: () {},
          ),
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
                        child: Image.network(
                          widget.imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
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
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${comments.length} 条评论',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(widget.authorAvatar),
                      ),
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
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          _commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...comments.map((c) => ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(c['avatar']!)),
                  title: Text(c['name']!),
                  subtitle: Text(c['text']!),
                )),
                const SizedBox(height: 24),
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
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(widget.authorAvatar),
                  ),
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
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      _commentController.clear();
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
