import 'package:flutter/material.dart';

class MerchantPage extends StatelessWidget {
  final int mid;

  const MerchantPage({super.key, required this.mid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店铺'), backgroundColor: Colors.red),
      body: const Center(child: Text('这是店铺页面', style: TextStyle(fontSize: 18))),
    );
  }
}
