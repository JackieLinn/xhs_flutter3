import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: const Center(
        child: Text('这里是注册页面', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
