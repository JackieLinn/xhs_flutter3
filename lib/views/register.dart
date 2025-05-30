import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xhs/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeat = true;

  bool _isSendingCode = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isSendingCode = true;
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        setState(() => _isSendingCode = false);
      }
    });
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写电子邮件地址')));
      return;
    }
    // 验证邮箱格式
    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailReg.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入合法的邮箱地址')));
      return;
    }

    try {
      await ApiService.getVoid(
        '/auth/ask-code',
        queryParameters: {'email': email, 'type': 'register'},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验证码已发送')));
      _startCountdown();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请求验证码失败: $e')));
    }
  }

  Future<void> _register() async {
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final repeat = _repeatController.text.trim();
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if ([
      phone,
      username,
      password,
      repeat,
      email,
      code,
    ].any((s) => s.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写所有字段')));
      return;
    }
    // 再次校验邮箱
    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailReg.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入合法的邮箱地址')));
      return;
    }
    // 校验密码一致
    if (password != repeat) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次密码输入不一致')));
      return;
    }
    // 验证码必须为 6 位数字
    final codeReg = RegExp(r'^\d{6}$');
    if (!codeReg.hasMatch(code)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验证码格式不正确')));
      return;
    }

    try {
      final payload = {
        'phone': phone,
        'username': username,
        'password': password,
        'email': email,
        'code': code,
      };
      await ApiService.postVoid('/auth/register', data: payload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('注册成功')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注册失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle = TextStyle(fontSize: 14, color: Colors.grey.shade600);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('注册'),
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

            // 各种输入框
            _buildField(_phoneController, '电话号码', Icons.phone, hintStyle),
            const SizedBox(height: 14),
            _buildField(
              _usernameController,
              '用户名/邮箱',
              Icons.person_outline,
              hintStyle,
            ),
            const SizedBox(height: 14),
            _buildField(
              _passwordController,
              '密码',
              Icons.lock_outline,
              hintStyle,
              obscure: _obscurePassword,
              toggle:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 14),
            _buildField(
              _repeatController,
              '重复密码',
              Icons.lock_outline,
              hintStyle,
              obscure: _obscureRepeat,
              toggle: () => setState(() => _obscureRepeat = !_obscureRepeat),
            ),
            const SizedBox(height: 14),
            _buildField(
              _emailController,
              '电子邮件地址',
              Icons.email_outlined,
              hintStyle,
            ),
            const SizedBox(height: 14),

            // 验证码 + 获取按钮
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _codeController,
                    '请输入验证码',
                    Icons.verified_user,
                    hintStyle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.red.shade100; // 禁用时浅红
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.red.shade900; // 按下时深红
                        }
                        return Colors.red.shade700; // 默认深红
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.red.shade700; // 禁用时文字红
                        }
                        return Colors.white; // 默认文字白
                      }),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    onPressed: _isSendingCode ? null : _requestCode,
                    child: Text(
                      _isSendingCode ? '请稍后 $_secondsRemaining s' : '获取验证码',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 立即注册
            SizedBox(
              height: 38,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.red.shade900;
                    }
                    return Colors.red.shade700;
                  }),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: _register,
                child: const Text(
                  '立即注册',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 已有账号？立即登录
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '已有账号？',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '立即登录',
                    style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon,
    TextStyle hintStyle, {
    bool obscure = false,
    VoidCallback? toggle,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 35,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade700),
          hintText: hint,
          hintStyle: hintStyle,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          suffixIcon:
              toggle != null
                  ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: toggle,
                  )
                  : null,
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
