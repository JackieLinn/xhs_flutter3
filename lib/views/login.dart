import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';
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
  final _storage = const FlutterSecureStorage();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // 尝试读取之前保存的用户名和密码
    final savedUser = await _storage.read(key: 'saved_username');
    final savedPass = await _storage.read(key: 'saved_password');
    if (savedUser != null && savedPass != null) {
      setState(() {
        _usernameController.text = savedUser;
        _passwordController.text = savedPass;
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Logo
            Center(
              child: Image.asset(
                'images/xhs_logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),

            // 用户名输入框
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
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 14),

            // 密码输入框
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
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                      onChanged:
                          (v) => setState(() => _rememberMe = v ?? false),
                      side: BorderSide(color: Colors.grey.shade600, width: 1),
                      activeColor: Colors.red.shade700,
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
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ResetPasswordPage(),
                        ),
                      ),
                  child: Text(
                    '忘记密码？',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 登录按钮
            SizedBox(
              height: 38,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(WidgetState.pressed)
                            ? Colors.red.shade900
                            : Colors.red.shade700,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () async {
                  final username = _usernameController.text.trim();
                  final password = _passwordController.text;
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请填写用户名/邮箱')));
                    return;
                  }
                  if (password.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请填写密码')));
                    return;
                  }

                  try {
                    // 调用登录接口
                    await ApiService.login(
                      username: username,
                      password: password,
                      remember: _rememberMe,
                    );

                    // 根据 remember 存／删凭据
                    if (_rememberMe) {
                      await _storage.write(
                        key: 'saved_username',
                        value: username,
                      );
                      await _storage.write(
                        key: 'saved_password',
                        value: password,
                      );
                    } else {
                      await _storage.delete(key: 'saved_username');
                      await _storage.delete(key: 'saved_password');
                    }

                    // 读取并打印 token
                    final authStr = await _storage.read(key: 'access_token');
                    print('登录成功，token=$authStr');

                    // 跳转首页
                    Navigator.pushReplacementNamed(context, '/home');
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text(
                  '立即登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 分隔文字
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade600,
                    thickness: 1,
                    indent: 20,
                    endIndent: 10,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '没有账号',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade600,
                    thickness: 1,
                    indent: 10,
                    endIndent: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 注册账号
            SizedBox(
              height: 38,
              child: OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(WidgetState.pressed)
                            ? Colors.red.shade50
                            : Colors.white,
                  ),
                  side: WidgetStateProperty.resolveWith<BorderSide>(
                    (states) => BorderSide(
                      color:
                          states.contains(WidgetState.pressed)
                              ? Colors.red.shade700
                              : Colors.red,
                      width: 1,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) =>
                        states.contains(WidgetState.pressed)
                            ? Colors.red.shade700
                            : Colors.red,
                  ),
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const RegisterPage()),
                    ),
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
