import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => Page2State();
}

class Page2State extends State<Page2> {
  final List<String> videoUrls = [
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ];

  VideoPlayerController? _currentController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeController(_currentPage);
  }

  void _initializeController(int index) async {
    _currentController?.dispose(); // 释放上一个视频
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrls[index]));
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(1.0);
    controller.play();
    setState(() {
      _currentController = controller;
    });
  }

  // 新增方法：用于暂停视频
  void pauseVideo() {
    _currentController?.pause();
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
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videoUrls.length,
        onPageChanged: (index) {
          _initializeController(index);
          _currentPage = index;
        },
        itemBuilder: (context, index) {
          final isCurrent = index == _currentPage;
          return Stack(
            children: [
              // 视频播放器
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

              // 左下角头像、昵称、关注按钮、标题
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
                          backgroundImage: NetworkImage(
                            'https://picsum.photos/seed/avatar$index/200/200',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '@作者$index',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '关注',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这是一个视频的标题描述，展示给用户看。',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // 右侧点赞、评论、分享、收藏
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text('123', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text('45', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text('分享', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text('收藏', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),

              // 中间播放/暂停图标
              if (isCurrent && _currentController != null && _currentController!.value.isInitialized)
                Center(
                  child: _currentController!.value.isPlaying
                      ? const SizedBox()
                      : const Icon(Icons.play_arrow, color: Colors.white, size: 80),
                ),
            ],
          );
        },
      ),
    );
  }
}
