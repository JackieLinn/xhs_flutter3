import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_vo.dart';
import '../models/cart_update_ro.dart';
import '../models/orders_create_ro.dart';
import '../services/api_service.dart';
import 'single_order_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _storage = const FlutterSecureStorage();
  List<CartVO> _carts = [];
  bool _isLoading = true;
  String? _errorMsg;
  Map<int, bool> _updatingStates = {}; // 记录每个商品的更新状态
  int? _selectedCartId; // 记录选中的购物车ID

  @override
  void initState() {
    super.initState();
    _loadCarts();
  }

  Future<int> _getUid() async {
    final raw = await _storage.read(key: 'access_token');
    if (raw == null) return 0;
    final obj = jsonDecode(raw) as Map<String, dynamic>;
    return int.tryParse(obj['id'] as String) ?? 0;
  }

  Future<void> _loadCarts() async {
    try {
      final uid = await _getUid();
      final rawData = await ApiService.getApi(
        '/api/cart/get-all-carts',
        queryParameters: {'uid': uid.toString()},
      );
      final List<dynamic> dataList = rawData as List<dynamic>;
      setState(() {
        _carts = dataList.map((e) => CartVO.fromJson(e as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = '加载失败：$e';
        _isLoading = false;
      });
    }
  }

  void _changeQty(CartVO cart, bool add) async {
    if (!add && cart.quantity == 1) {
      _showRemoveDialog(cart);
      return;
    }

    setState(() => _updatingStates[cart.cid] = true);

    try {
      final type = add ? 1 : 0;
      await ApiService.postApi(
        '/api/cart/update-cart',
        data: CartUpdateRO(cid: cart.cid, type: type).toJson(),
      );
      
      setState(() {
        final index = _carts.indexWhere((c) => c.cid == cart.cid);
        if (index != -1) {
          _carts[index] = CartVO(
            cid: cart.cid,
            name: cart.name,
            image: cart.image,
            price: cart.price,
            quantity: cart.quantity + (add ? 1 : -1),
            attributes: cart.attributes,
          );
        }
        _updatingStates[cart.cid] = false;
      });
    } catch (e) {
      setState(() => _updatingStates[cart.cid] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e')),
        );
      }
    }
  }

  void _showRemoveDialog(CartVO cart) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除商品'),
        content: const Text('确定要移除该商品？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.postApi(
                  '/api/cart/update-cart',
                  data: CartUpdateRO(cid: cart.cid, type: 0).toJson(),
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _carts.removeWhere((c) => c.cid == cart.cid);
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('移除失败：$e')),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  double get _totalPrice {
    if (_selectedCartId == null) return 0;
    final selectedCart = _carts.firstWhere((cart) => cart.cid == _selectedCartId);
    return selectedCart.price * selectedCart.quantity;
  }

  CartVO? get _selectedCart {
    if (_selectedCartId == null) return null;
    return _carts.firstWhere((cart) => cart.cid == _selectedCartId);
  }

  Future<void> _navigateToOrder() async {
    if (_selectedCartId == null) return;
    
    final selectedCart = _carts.firstWhere((cart) => cart.cid == _selectedCartId);
    final auth = await ApiService.getAuthObject();
    final uid = int.parse(auth['id'] as String);

    final order = OrdersCreateRO(
      cid: selectedCart.cid,
      uid: uid,
      price: selectedCart.price,
      quantity: selectedCart.quantity,
    );

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleOrderPage(
          order: order,
          productName: selectedCart.name,
          productImage: selectedCart.image,
          productAttributes: selectedCart.attributes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                '购物车',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(child: Text(_errorMsg!))
              : _carts.isEmpty
                  ? const Center(child: Text('购物车为空'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _carts.length,
                            itemBuilder: (context, index) {
                              final cart = _carts[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 单选按钮
                                      Radio<int>(
                                        value: cart.cid,
                                        groupValue: _selectedCartId,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedCartId = value;
                                          });
                                        },
                                      ),
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
                                      // 商品信息
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
                                                      onTap: _updatingStates[cart.cid] == true
                                                          ? null
                                                          : () => _changeQty(cart, false),
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
                                                      '${cart.quantity}',
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // 加号
                                                    GestureDetector(
                                                      onTap: _updatingStates[cart.cid] == true
                                                          ? null
                                                          : () => _changeQty(cart, true),
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
                                ),
                              );
                            },
                          ),
                        ),
                        // 底部结算栏
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '总价：¥${_totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _selectedCartId == null
                                    ? null
                                    : _navigateToOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(100, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('去下单'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
