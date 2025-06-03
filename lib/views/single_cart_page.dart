import 'package:flutter/material.dart';

import '../models/cart_list_one_ro.dart';
import './single_order_page.dart';

class SingleCartPage extends StatefulWidget {
  final CartListOneRO cartItem;

  const SingleCartPage({super.key, required this.cartItem});

  @override
  State<SingleCartPage> createState() => _SingleCartPageState();
}

class _SingleCartPageState extends State<SingleCartPage> {
  // 原先用 late 定义，这里改成带初始值，避免未初始化时被 build 调用
  int _quantity = 0;
  double _unitPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // 在 initState 中，把从外部传进来的值赋给它们
    _quantity = widget.cartItem.quantity;
    _unitPrice = widget.cartItem.price;
  }

  @override
  Widget build(BuildContext context) {
    // 计算“总价”
    final double totalPrice = _unitPrice * _quantity;

    return Scaffold(
      // ========== AppBar ==========
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
              // 左侧返回箭头
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              // 中间标题 “购物车”
              const Expanded(
                child: Text(
                  '购物车',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // 右侧“管理”按钮（暂时留空）
              TextButton(
                onPressed: () {
                  // TODO: “管理” 的实际操作
                },
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  minimumSize: MaterialStateProperty.all(const Size(60, 40)),
                ),
                child: const Text(
                  '管理',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),

      // ========== Body ==========
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：商品图片（正方形 100×100），这里先写死 URL
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade200,
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(
                    'https://www.58fuke.com/download/temp/20250531/1748676159_7_eac27167_4ff6_476e_a20e_42793d92a72b.png',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 右侧：三行内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：商品名称（单行显示，超出省略，这里写死示例文字）
                  const Text(
                    'polo领连衣裙女夏季韩版2024新款时尚休闲',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第二行：灰色椭圆背景，黑色字体 “红色、S” （写死示例）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '红色、S',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 第三行：左侧单价（红色），右侧数量加减器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 单价，用 _unitPrice 动态展示
                      Text(
                        '¥${_unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 数量加减器
                      Row(
                        children: [
                          // “-” 号
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 数量文本
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // “+” 号
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ========== Bottom Bar：总价 + 结算按钮 ==========
      bottomNavigationBar: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧：总价（动态显示 totalPrice）
            Expanded(
              child: Text(
                '总价：¥${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // 右侧：红底白字“结算”按钮（点击跳转到 SingleOrderPage）
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SingleOrderPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                '结算',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
