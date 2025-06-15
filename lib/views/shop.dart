import 'package:flutter/material.dart';

import '../components/product_card.dart';
import '../models/product_vo.dart';
import '../services/api_service.dart';
import 'cart_page.dart';
import 'category_page.dart';
import 'orders_page.dart';
import 'store_page.dart';
import 'product_detail_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<ProductVO>> _futureProducts;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ProductVO> _searchResults = [];
  bool _showSearchResults = false;
  String? _searchErrorMsg; // New: to show search errors
  bool _isSearching = false; // New: to show search loading

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchRecommendProducts();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSearchResults = _searchFocusNode.hasFocus && (_searchResults.isNotEmpty || _isSearching || _searchErrorMsg != null || _searchController.text.isNotEmpty);
    });
  }

  void _onSearchChanged() {
    // Remove real-time search, only search on enter
  }

  void _submitSearch(String keyword) {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchErrorMsg = null;
      });
    } else {
      _performSearch(keyword);
    }
  }

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isSearching = true;
      _searchErrorMsg = null;
      _showSearchResults = true;
    });
    try {
      final rawData = await ApiService.getApi(
        '/api/product/search',
        queryParameters: {'keyword': keyword},
      );
      final List<dynamic> dataList = rawData as List<dynamic>;
      setState(() {
        _searchResults = dataList.map((e) => ProductVO.fromJson(e as Map<String, dynamic>)).toList();
        _isSearching = false;
        _showSearchResults = true; // Always show results after search
      });
    } catch (e) {
      setState(() {
        _searchErrorMsg = '搜索失败: $e';
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = true; // Always show results after search
      });
    }
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
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: '搜你想要的商品',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _submitSearch, // Add search on enter
                    textInputAction: TextInputAction.search, // Show search icon on keyboard
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
      body: Stack(
        children: [
          Column(
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
                              delegate: SliverChildBuilderDelegate(( context, index) {
                                final item = products[index];
                                return ProductCard(
                                  image: item.image,
                                  name: item.name,
                                  activity: item.activity,
                                  price: item.price, // 传 double
                                  payers: item.payers,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => ProductDetailPage(product: item),
                                      ),
                                    );
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
          // Search Results Overlay
          if (_showSearchResults)
            Positioned(
              top: 60 + 8, // AppBar height + gap
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  setState(() { _showSearchResults = false; });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.3), // Semi-transparent background
                  child: Container(
                    margin: const EdgeInsets.only(top: 8), // Add gap between search bar and results
                    color: Colors.white,
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : _searchErrorMsg != null
                            ? Center(child: Text(_searchErrorMsg!))
                            : _searchResults.isEmpty && _searchController.text.isNotEmpty
                                ? const Center(child: Text('未找到相关商品'))
                                : _searchController.text.isEmpty && _searchFocusNode.hasFocus
                                    ? const Center(child: Text('请输入搜索关键词'))
                                    : ListView.builder(
                                        itemCount: _searchResults.length,
                                        padding: const EdgeInsets.all(8.0),
                                        itemBuilder: (context, index) {
                                          final product = _searchResults[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.1),
                                                  spreadRadius: 1,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListTile(
                                              leading: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  product.image,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              title: Text(
                                                product.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '¥${product.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onTap: () {
                                                _searchFocusNode.unfocus();
                                                setState(() { _showSearchResults = false; });
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (c) => ProductDetailPage(product: product),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 弹出"更多"侧面板（ModalBottomSheet）
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
