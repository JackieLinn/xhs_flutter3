import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_list_one_ro.dart';
import '../models/cart_update_ro.dart';
import '../models/cart_vo.dart';
import '../models/orders_create_ro.dart';
import '../services/api_service.dart';
import 'single_order_page.dart';

class SingleCartPage extends StatefulWidget {
  final CartListOneRO cartItem;
  const SingleCartPage({Key? key, required this.cartItem}) : super(key: key);

  @override
  _SingleCartPageState createState() => _SingleCartPageState();
}

class _SingleCartPageState extends State<SingleCartPage> {
  final _storage = const FlutterSecureStorage();
  CartVO? _cart;
  int _quantity = 0;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  /// 只调用一次 “保存并获取单个购物车” 接口
  void _fetchCart() {
    ApiService.postApi('/api/cart/get-cart', data: widget.cartItem.toJson())
        .then((data) {
      final vo = CartVO.fromJson(data as Map<String, dynamic>);
      setState(() {
        _cart = vo;
        _quantity = vo.quantity;
        _loading = false;
      });
    })
        .catchError((e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载失败：$e')));
    });
  }

  /// 从存储里读取当前用户 ID
  Future<int> _getUid() async {
    final raw = await _storage.read(key: 'access_token');
    if (raw == null) return 0;
    final obj = jsonDecode(raw) as Map<String, dynamic>;
    return int.tryParse(obj['id'] as String) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_cart == null) {
      return const Scaffold(body: Center(child: Text('购物车为空')));
    }

    final cart = _cart!;
    final totalPrice = cart.price * _quantity;

    return Scaffold(
      // ===== 统一风格的 AppBar =====
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
                  '购物车',
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
                  // TODO: 管理操作
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== 商品信息行 =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品图片
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(cart.image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 名称 / 属性 / 价格 + 加减
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(cart.attributes.join('，')),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥${cart.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // 减号
                              GestureDetector(
                                onTap:
                                _updating ? null : () => _changeQty(false),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.remove, size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              // 加号
                              GestureDetector(
                                onTap:
                                _updating ? null : () => _changeQty(true),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.add, size: 18),
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

            const Spacer(),
            Container(
              width: MediaQuery.of(context).size.width,  // 使用 MediaQuery 确保横线占满屏幕宽度
              height: 1,  // 横线的高度
              color: Colors.grey.shade300,  // 横线的颜色
            ),

            // ===== 底部：总价 + 结算按钮 =====
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '总价：¥${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final uid = await _getUid();
                      final order = OrdersCreateRO(
                        cid: cart.cid,
                        uid: uid,
                        price: cart.price,
                        quantity: _quantity,
                      );
                      // 传递商品数据到订单页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SingleOrderPage(
                            order: order,
                            productName: cart.name, // 商品名称
                            productImage: cart.image, // 商品图片
                            productAttributes: cart.attributes, // 商品属性
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('结算'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 改变数量：add=true 加，add=false 减
  void _changeQty(bool add) {
    if (!add && _quantity == 1) {
      _showRemoveDialog();
      return;
    }
    setState(() => _updating = true);

    final type = add ? 1 : 0;
    ApiService.postApi(
      '/api/cart/update-cart',
      data: CartUpdateRO(cid: _cart!.cid, type: type).toJson(),
    )
        .then((_) {
      setState(() {
        _quantity += add ? 1 : -1;
        _updating = false;
      });
    })
        .catchError((e) {
      setState(() => _updating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新失败：$e')));
    });
  }

  /// 弹出“移除商品”确认框
  void _showRemoveDialog() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: const Text('移除商品'),
        content: const Text('确定要移除该商品？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ApiService.postApi(
                '/api/cart/update-cart',
                data: CartUpdateRO(cid: _cart!.cid, type: 0).toJson(),
              )
                  .then((_) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              })
                  .catchError((e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('移除失败：$e')));
              });
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
