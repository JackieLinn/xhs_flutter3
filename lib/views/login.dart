import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: ElevatedButton(
          child: const Text('登录'),
          onPressed: () {
            // 点击登录，跳转到首页
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
    );
  }
}
