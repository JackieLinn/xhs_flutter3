import 'package:flutter/material.dart';
import '../models/cart_list_one_ro.dart';

class SingleCartPage extends StatelessWidget {
  final CartListOneRO cartItem;

  const SingleCartPage({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已加入购物车'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          '已接收信息：\n'
              'UID = ${cartItem.uid}\n'
              'PID = ${cartItem.pid}\n'
              '单价 = ¥${cartItem.price.toStringAsFixed(2)}\n'
              '数量 = ${cartItem.quantity}\n'
              '属性IDs = ${cartItem.aoids}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
