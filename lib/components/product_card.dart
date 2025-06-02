import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String image; // 后端 image URL
  final String name; // 商品名
  final String activity; // 活动文案
  final double price; // 用 double 存储价格
  final int payers; // 已购人数
  final int nameMaxLines; // 名称最多显示行数
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.activity,
    required this.price,
    required this.payers,
    this.onTap,
    this.nameMaxLines = 2, // 默认两行
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            // 图片部分，占比 2/3
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 商品信息，占比 1/3
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名：使用 nameMaxLines 控制行数
                    Text(
                      name,
                      maxLines: nameMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 活动
                    Text(
                      activity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 价格：这里把 double 转 String，保留两位小数
                        Text(
                          '¥ ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        // 已购人数
                        Row(
                          children: [
                            const Icon(Icons.people, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              payers.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
