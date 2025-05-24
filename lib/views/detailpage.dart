import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String title;
  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text("这里是 $title 的详情页", style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
