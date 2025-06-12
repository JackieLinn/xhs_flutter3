import 'package:flutter/material.dart';

class DraftsPage extends StatelessWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的草稿'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          '这里是我的草稿页面',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}