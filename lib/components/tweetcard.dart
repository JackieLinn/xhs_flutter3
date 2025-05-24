import 'package:flutter/material.dart';

class TweetCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String avatarUrl;
  final String username;
  final int likes;
  final VoidCallback? onTap;

  const TweetCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.avatarUrl,
    required this.username,
    required this.likes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 改小圆角
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片部分，占比 3/4
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), // 更小的圆角
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 标题 + 底部信息，占比 1/4
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                          radius: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.favorite, size: 14, color: Colors.red),
                        const SizedBox(width: 2),
                        Text(likes.toString(), style: const TextStyle(fontSize: 12)),
                      ],
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