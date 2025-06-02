import 'package:flutter/material.dart';

import '../components/product_card.dart';
import '../models/product_vo.dart';
import '../services/api_service.dart';
import 'cart_page.dart';
import 'category_page.dart';
import 'orders_page.dart';
import 'store_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<ProductVO>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchRecommendProducts();
  }

  /// 调用后端 /api/product/get-recommend-products，返回 List<ProductVO>
  Future<List<ProductVO>> _fetchRecommendProducts() async {
    final rawData = await ApiService.getApi(
      '/api/product/get-recommend-products',
    );
    final List<dynamic> dataList = rawData as List<dynamic>;
    return dataList
        .map((e) => ProductVO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 下拉刷新时调用，重新请求并更新 Future
  Future<void> _onRefresh() async {
    final newFuture = _fetchRecommendProducts();
    setState(() {
      _futureProducts = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 保持不变
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜你想要的商品',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Colors.grey.shade800),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CartPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade800),
                  onPressed: () {
                    _showMorePanel(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 顶部四个图标行保持不变
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CategoryPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.category,
                          color: Colors.grey.shade800,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '商品分类',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const OrdersPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          color: Colors.grey.shade800,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '我的订单',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CartPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.grey.shade800,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '购物车',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const StorePage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store,
                          color: Colors.grey.shade800,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        const Text('店铺', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 商品列表与下拉刷新
          Expanded(
            child: FutureBuilder<List<ProductVO>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败：${snapshot.error}'));
                }
                final products = snapshot.data ?? [];

                // 使用 RefreshIndicator 包裹 CustomScrollView，实现下拉刷新
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.65, // 图片:文字 = 2:1
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = products[index];
                            return ProductCard(
                              image: item.image,
                              name: item.name,
                              activity: item.activity,
                              price: item.price, // 传 double
                              payers: item.payers,
                              onTap: () {
                                // 点击跳转详情或其他操作
                              },
                            );
                          }, childCount: products.length),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => const CategoryPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                '点击查看更多',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 弹出“更多”侧面板（ModalBottomSheet）
  void _showMorePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.category, color: Colors.grey),
                title: const Text('商品分类'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const CategoryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.grey),
                title: const Text('我的订单'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const OrdersPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.grey),
                title: const Text('购物车'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const CartPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.grey),
                title: const Text('店铺'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const StorePage()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
