import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('重置密码')),
      body: const Center(
        child: Text('这里是重置密码页面', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
