import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xhs/services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  int _stepIndex = 0;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

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

  Future<void> _handleStep1() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    // 验证邮箱
    if (email.isEmpty) {
      _showMsg('请填写电子邮件地址');
      return;
    }
    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailReg.hasMatch(email)) {
      _showMsg('请输入合法的邮箱地址');
      return;
    }
    // 验证码
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMsg('请输入6位数字验证码');
      return;
    }
    try {
      // 先请求确认接口
      await ApiService.postVoid(
        '/auth/reset-confirm',
        data: {'email': email, 'code': code},
      );
      _showMsg('验证通过，进入下一步');
      setState(() => _stepIndex = 1);
    } catch (e) {
      _showMsg('验证失败：$e');
    }
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg('请填写电子邮件地址');
      return;
    }
    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailReg.hasMatch(email)) {
      _showMsg('请输入合法的邮箱地址');
      return;
    }
    try {
      await ApiService.getVoid(
        '/auth/ask-code',
        queryParameters: {'email': email, 'type': 'reset'},
      );
      _showMsg('验证码已发送');
      _startCountdown();
    } catch (e) {
      _showMsg('请求验证码失败：$e');
    }
  }

  Future<void> _handleStep2() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPwdController.text;
    final confirm = _confirmPwdController.text;
    if (newPassword.isEmpty || confirm.isEmpty) {
      _showMsg('请填写新密码和确认密码');
      return;
    }
    if (newPassword != confirm) {
      _showMsg('两次密码输入不一致');
      return;
    }
    try {
      await ApiService.postVoid(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'password': newPassword},
      );
      _showMsg('重置密码成功');
      Navigator.pop(context);
    } catch (e) {
      _showMsg('重置失败：$e');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle = TextStyle(fontSize: 14, color: Colors.grey.shade600);

    ButtonStyle redBtnStyle(double radius) => ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.pressed)
            ? Colors.red.shade900
            : Colors.red.shade700;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('重置密码'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'images/xhs_logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),

            // 步骤条
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepItem(1, '验证邮箱', _stepIndex == 0),
                _buildStepLine(),
                _buildStepItem(2, '重设密码', _stepIndex == 1),
              ],
            ),
            const SizedBox(height: 20),

            // 步骤内容
            if (_stepIndex == 0) ...[
              _buildField(
                controller: _emailController,
                hint: '电子邮件地址',
                icon: Icons.email_outlined,
                hintStyle: hintStyle,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _codeController,
                      hint: '请输入验证码',
                      icon: Icons.verified_user,
                      hintStyle: hintStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (_isSendingCode) return Colors.red.shade100;
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.red.shade900;
                            }
                            return Colors.red.shade700;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) =>
                              _isSendingCode
                                  ? Colors.red.shade700
                                  : Colors.white,
                        ),
                        mouseCursor:
                            WidgetStateProperty.resolveWith<MouseCursor>(
                              (_) =>
                                  _isSendingCode
                                      ? SystemMouseCursors.forbidden
                                      : SystemMouseCursors.click,
                            ),
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
                        _isSendingCode ? '请稍后 ${_secondsRemaining}s' : '获取验证码',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  style: redBtnStyle(10),
                  onPressed: _handleStep1,
                  child: const Text(
                    '开始重置密码',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              _buildField(
                controller: _newPwdController,
                hint: '新密码',
                icon: Icons.lock_outline,
                hintStyle: hintStyle,
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmPwdController,
                hint: '确认密码',
                icon: Icons.lock_outline,
                hintStyle: hintStyle,
                obscure: _obscureConfirm,
                toggle:
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  style: redBtnStyle(10),
                  onPressed: _handleStep2,
                  child: const Text(
                    '立即重置密码',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
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

  Widget _buildStepItem(int number, String title, bool active) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? Colors.red.shade700 : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: active ? Colors.red.shade700 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 24,
      height: 1,
      color: Colors.grey.shade400,
    );
  }
}
