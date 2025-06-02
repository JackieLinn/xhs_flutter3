// File: lib/views/product_detail_page.dart

import 'package:flutter/material.dart';

import '../models/product_vo.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductVO product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 占位：显示商品图片
            Center(
              child: Image.network(
                product.image,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            // 占位：显示商品名称
            Text(
              product.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 占位：显示活动文案
            Text(
              product.activity,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 8),
            // 占位：显示价格与已购人数
            Row(
              children: [
                Text(
                  '¥ ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      product.payers.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 占位：更多商品信息
            const Text(
              '这里是商品的详细信息占位，后续可以展示描述、规格等。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
