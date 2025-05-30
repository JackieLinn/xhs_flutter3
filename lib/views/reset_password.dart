import 'dart:async';

import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  int _stepIndex = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // 验证码冷却
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
        setState(() {
          _isSendingCode = false;
        });
      }
    });
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

            // 步骤条
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepItem(1, '验证电子邮件', _stepIndex == 0),
                  _buildStepLine(),
                  _buildStepItem(2, '重新设定密码', _stepIndex == 1),
                ],
              ),
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
                            return states.contains(WidgetState.pressed)
                                ? Colors.red.shade900
                                : Colors.red.shade700;
                          },
                        ),
                        mouseCursor:
                            WidgetStateProperty.resolveWith<MouseCursor>(
                              (states) =>
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
                      onPressed:
                          _isSendingCode
                              ? null
                              : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('验证码已发送~')),
                                );
                                _startCountdown();
                              },
                      child: Text(
                        _isSendingCode ? '请稍后 ${_secondsRemaining}s' : '获取验证码',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _isSendingCode
                                  ? Colors.red.shade700
                                  : Colors.white,
                        ),
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
                  onPressed: () {
                    setState(() => _stepIndex = 1);
                  },
                  child: const Text(
                    '开始重置密码',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('重置密码成功~')));
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '立即重置密码',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
