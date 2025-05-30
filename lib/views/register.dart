import 'dart:async';

import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isSendingCode = false;
        });
      }
    });
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

            // 电话号码
            _buildField(
              controller: _phoneController,
              hint: '电话号码',
              icon: Icons.phone,
              hintStyle: hintStyle,
            ),
            const SizedBox(height: 14),

            // 用户名/邮箱
            _buildField(
              controller: _usernameController,
              hint: '用户名/邮箱',
              icon: Icons.person_outline,
              hintStyle: hintStyle,
            ),
            const SizedBox(height: 14),

            // 密码
            _buildField(
              controller: _passwordController,
              hint: '密码',
              icon: Icons.lock_outline,
              hintStyle: hintStyle,
              obscure: _obscurePassword,
              toggle:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 14),

            // 重复密码
            _buildField(
              controller: _repeatController,
              hint: '重复密码',
              icon: Icons.lock_outline,
              hintStyle: hintStyle,
              obscure: _obscureRepeat,
              toggle: () => setState(() => _obscureRepeat = !_obscureRepeat),
            ),
            const SizedBox(height: 14),

            // 电子邮件地址
            _buildField(
              controller: _emailController,
              hint: '电子邮件地址',
              icon: Icons.email_outlined,
              hintStyle: hintStyle,
            ),
            const SizedBox(height: 14),

            // 验证码 + 获取按钮
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _codeController,
                    hint: '请输入验证码',
                    icon: Icons.verified_user,
                    hintStyle: hintStyle,
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>(
                        (states) {
                          return states.contains(WidgetState.disabled)
                              ? SystemMouseCursors.forbidden
                              : SystemMouseCursors.click;
                        },
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        // 倒计时中用浅红色，否则红色
                        if (_isSendingCode) {
                          return Colors.red.shade100;
                        }
                        return states.contains(WidgetState.pressed)
                            ? Colors.red.shade900
                            : Colors.red.shade700;
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
                    onPressed:
                        _isSendingCode
                            ? null
                            : () {
                              // 请求验证码成功提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请求验证码成功~')),
                              );
                              _startCountdown();
                            },
                    child: Text(
                      _isSendingCode ? '请稍后 ${_secondsRemaining}s' : '获取验证码',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _isSendingCode ? Colors.red.shade700 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 立即注册（样式同“立即登录”）
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
                onPressed: () {
                  Navigator.pop(context);
                },
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextStyle hintStyle,
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
