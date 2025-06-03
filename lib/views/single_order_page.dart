// File: lib/views/single_order_page.dart

import 'package:flutter/material.dart';

class SingleOrderPage extends StatelessWidget {
  const SingleOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 你可以仿照 SingleCartPage 里的 AppBar 样式
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  '确认订单',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: “管理”或其他操作
                },
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  minimumSize: MaterialStateProperty.all(const Size(60, 40)),
                ),
                child: const Text(
                  '管理',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Body 部分先用文字占位
      body: const Center(
        child: Text(
          '这里是“单一订单”页面占位\n\n后续可在此展示订单详情、收货地址、付款方式等',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
