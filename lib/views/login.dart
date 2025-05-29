import 'package:flutter/material.dart';

import 'register.dart';
import 'reset_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // 定义一个灰色小字体的hint样式
    var hintStyle = TextStyle(fontSize: 14, color: Colors.grey.shade600);

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('登录')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'images/xhs_logo.png', // 根据实际路径调整图片路径
                width: 150, // 设置logo的宽度，可以调整大小
                height: 150, // 设置logo的高度，可以调整大小
              ),
            ),
            const SizedBox(height: 20), // 添加一些间距
            // 用户名
            SizedBox(
              height: 35,
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  hintText: '用户名/邮箱',
                  hintStyle: hintStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade500,
                      width: 2,
                    ), // 设置焦点时的边框颜色和宽度
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ), // 设置未选中的边框颜色
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 14),

            // 密码
            SizedBox(
              height: 35,
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  hintText: '密码',
                  hintStyle: hintStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade500,
                      width: 2,
                    ), // 设置焦点时的边框颜色和宽度
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ), // 设置未选中的边框颜色
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),

            // 记住我 & 忘记密码
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) {
                        setState(() => _rememberMe = v ?? false);
                      },
                      side: BorderSide(color: Colors.grey.shade600, width: 1),
                    ),
                    Text(
                      '记住我',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ResetPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    '忘记密码？',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 立即登录（绿色，浅色默认，点击更深）
            SizedBox(
              height: 38,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.green.shade200
                            : Colors.green.shade100,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text(
                  '立即登录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 分隔文字
            Center(
              child: Text(
                '—————— 没有账号 ——————',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 12),

            // 注册账号（橙色，浅色默认，点击更深）
            SizedBox(
              height: 38,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(MaterialState.pressed)
                            ? Colors.orange.shade200
                            : Colors.orange.shade100,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const RegisterPage()),
                  );
                },
                child: const Text(
                  '注册账号',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
