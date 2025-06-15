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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ProductVO> _searchResults = [];
  bool _showSearchResults = false;
  String? _searchErrorMsg;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _futureProducts = _fetchAllProducts();
    _searchFocusNode.addListener(_onFocusChanged);
    // _searchController.addListener(_onSearchChanged); // 移除实时监听，改为按Enter搜索
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      // 只有在搜索框有焦点且已有搜索结果、正在搜索或有错误时才显示悬浮层
      // 或者当输入框有内容，但还没有搜索时，也显示悬浮层以供后续搜索
      _showSearchResults = _searchFocusNode.hasFocus && (_searchResults.isNotEmpty || _isSearching || _searchErrorMsg != null || _searchController.text.isNotEmpty);
    });
  }

  // 当用户按下回车键（或键盘上的搜索按钮）时调用
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

  Future<void> _loadCategories() async {
    try {
      final rawData = await ApiService.getApi(
        '/api/product-classification/get-all-categories',
      );
      final List<dynamic> dataList = rawData as List<dynamic>;
      final fetched = dataList
          .map((e) => ProductClassification.fromJson(e as Map<String, dynamic>))
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
    _searchFocusNode.unfocus(); // Close keyboard and search overlay
    setState(() {
      _showSearchResults = false; // Explicitly hide search results
      _selectedIndex = index;
      if (index == 0) {
        _futureProducts = _fetchAllProducts();
      }
      else {
        final typeId = _categories[index].id;
        _futureProducts = _fetchProductsByType(typeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    return Scaffold(
      // 与 ShopPage 保持一致的 AppBar
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
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
                    onSubmitted: _submitSearch, // Trigger search on Enter
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
              ],
            ),
          ),
        ),
      ),

      // SafeArea + Row with stretch + bottom padding on GridView
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMsg != null
                    ? Center(child: Text(_errorMsg!))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 左侧分类导航
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
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 24,
                                          color: isSelected ? Colors.red : Colors.transparent,
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
                                                color: isSelected ? Colors.red : Colors.black,
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

                          // 右侧商品区域
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                  if (products.isEmpty) {
                                    return const Center(child: Text('暂无商品'));
                                  }
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GridView.builder(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 0.6,
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
                                            nameMaxLines: 1,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (c) => ProductDetailPage(product: item),
                                                ),
                                              );
                                            },
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
          ),
          // Search Results Overlay
          if (_showSearchResults)
            Positioned(
              top: appBarHeight + 8, // Add some space below the search bar
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
}
