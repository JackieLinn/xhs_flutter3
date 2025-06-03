import 'package:flutter/material.dart';

class SingleCartPage extends StatelessWidget {
  const SingleCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已加入购物车'), backgroundColor: Colors.red),
      body: const Center(
        child: Text(
          '这是单个购物车页面\n（这里只用文字占位，可根据需求再丰富）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
