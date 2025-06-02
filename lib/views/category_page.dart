import 'package:flutter/material.dart';

import '../components/product_card.dart';
import '../models/product_classification.dart';
import '../models/product_vo.dart';
import '../services/api_service.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<ProductClassification> _categories = [];
  Future<List<ProductVO>>? _futureProducts;
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _futureProducts = _fetchAllProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final rawData = await ApiService.getApi(
        '/api/product-classification/get-all-categories',
      );
      final List<dynamic> dataList = rawData as List<dynamic>;
      final fetched =
          dataList
              .map(
                (e) =>
                    ProductClassification.fromJson(e as Map<String, dynamic>),
              )
              .toList();
      setState(() {
        _categories = [ProductClassification(id: 0, name: '全部'), ...fetched];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = '加载分类失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<List<ProductVO>> _fetchAllProducts() async {
    final rawData = await ApiService.getApi('/api/product/get-all-products');
    final List<dynamic> dataList = rawData as List<dynamic>;
    return dataList
        .map((e) => ProductVO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductVO>> _fetchProductsByType(int type) async {
    final rawData = await ApiService.getApi(
      '/api/product/get-products-by-type',
      queryParameters: {'type': type.toString()},
    );
    final List<dynamic> dataList = rawData as List<dynamic>;
    return dataList
        .map((e) => ProductVO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _onCategoryTap(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        // “全部”
        _futureProducts = _fetchAllProducts();
      } else {
        final typeId = _categories[index].id;
        _futureProducts = _fetchProductsByType(typeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar: 与 ShopPage 保持一致
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // 返回箭头
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                // 搜索图标 + 搜索框
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
                // 购物车图标
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Colors.grey.shade800),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CartPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
              ? Center(child: Text(_errorMsg!))
              : Row(
                children: [
                  // 左侧导航栏
                  Container(
                    width: 85,
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_categories.length, (index) {
                        final bool isSelected = index == _selectedIndex;
                        return GestureDetector(
                          onTap: () => _onCategoryTap(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                // 选中时显示红色竖线
                                Container(
                                  width: 4,
                                  height: 24,
                                  color:
                                      isSelected
                                          ? Colors.red
                                          : Colors.transparent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      _categories[index].name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.red
                                                : Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 右侧商品展示
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: FutureBuilder<List<ProductVO>>(
                        future: _futureProducts,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('加载失败：${snapshot.error}'),
                            );
                          }
                          final products = snapshot.data ?? [];
                          if (products.isEmpty) {
                            return const Center(child: Text('暂无商品'));
                          }
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final item = products[index];
                              return ProductCard(
                                image: item.image,
                                name: item.name,
                                activity: item.activity,
                                price: item.price,
                                payers: item.payers,
                                nameMaxLines: 1, // 在分类页强制名称显示一行
                                onTap: () {
                                  // 点击跳转到商品详情页
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (c) =>
                                              ProductDetailPage(product: item),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
