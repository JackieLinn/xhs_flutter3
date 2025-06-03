// File: lib/views/merchant_page.dart

import 'package:flutter/material.dart';

class MerchantPage extends StatelessWidget {
  const MerchantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店铺'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          '这是店铺页面',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
