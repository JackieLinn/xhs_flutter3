import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome

import '../services/api_service.dart';
import '../models/product_vo.dart'; // 导入 ProductVO
import '../components/product_card.dart'; // 导入 ProductCard
import '../views/product_detail_page.dart'; // 导入 ProductDetailPage

class MerchantPage extends StatefulWidget {
  final int mid;

  const MerchantPage({super.key, required this.mid});

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  Map<String, dynamic>? merchant;
  List<ProductVO> _products = []; // 新增商品列表
  bool isLoading = true;
  String? errorMsg;
  final ScrollController _scrollController = ScrollController(); // 滚动控制器
  bool _showBackToTopButton = false; // 控制回到顶部按钮显示

  @override
  void initState() {
    super.initState();
    _fetchData(); // 统一调用
    _scrollController.addListener(() {
      final double scrollThreshold = 280 - kToolbarHeight; // 可滚动的灵活空间高度
      final bool shouldShow = _scrollController.offset >= scrollThreshold * 0.7; // 当70%滚动时出现

      if (shouldShow != _showBackToTopButton) {
        setState(() {
          _showBackToTopButton = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 释放滚动控制器
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      // 获取商家信息
      final merchantData = await ApiService.getApi(
        '/api/merchant/get-merchant-by-id',
        queryParameters: {'id': widget.mid.toString()},
      );
      // 获取商品列表
      final productRawData = await ApiService.getApi(
        '/api/product/get-products-by-mid',
        queryParameters: {'mid': widget.mid.toString()},
      );
      final List<dynamic> productList = productRawData as List<dynamic>;

      setState(() {
        merchant = merchantData as Map<String, dynamic>; // 确保类型转换
        _products = productList.map((e) => ProductVO.fromJson(e as Map<String, dynamic>)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = '加载失败：$e';
        isLoading = false;
      });
    }
  }

  // 回到顶部方法
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏图标为亮色，与深色AppBar背景形成对比
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarExpandedContentHeight = 280.0; // AppBar内容区域的高度 (不含状态栏)
    final double appBarTotalExpandedHeight = appBarExpandedContentHeight + statusBarHeight; // SliverAppBar的总高度

    return Scaffold(
      extendBodyBehindAppBar: true, // 让 SliverAppBar 背景延伸到状态栏
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : CustomScrollView(
                  controller: _scrollController, // 绑定滚动控制器
                  slivers: [
                    SliverAppBar(
                      expandedHeight: appBarTotalExpandedHeight,
                      pinned: true,
                      backgroundColor: const Color(0xFF512DA8),
                      automaticallyImplyLeading: false,
                      flexibleSpace: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double currentExtent = constraints.maxHeight;
                          final double minExtent = kToolbarHeight + statusBarHeight;
                          final double fade = (1 - ((currentExtent - minExtent) / (appBarExpandedContentHeight - kToolbarHeight))).clamp(0.0, 1.0);

                          return Stack(
                            children: [
                              // 背景渐变
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),

                              // 返回按钮
                              Positioned(
                                top: statusBarHeight,
                                left: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),

                              // 展开时的内容
                              Positioned(
                                top: statusBarHeight + kToolbarHeight,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Opacity(
                                  opacity: 1.0 - fade,
                                  child: Transform.translate(
                                    offset: Offset(0, -60 * fade),
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: merchant!["image"] != null && merchant!["image"].toString().isNotEmpty
                                                        ? Image.network(
                                                            merchant!["image"],
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Container(
                                                            width: 80,
                                                            height: 80,
                                                            color: Colors.grey.shade300,
                                                            child: const Icon(Icons.store, size: 40, color: Colors.white),
                                                          ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          merchant!["name"] ?? '',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          merchant!["introduction1"] ?? '',
                                                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                merchant!["address"] ?? '',
                                                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                merchant!["introduction2"] ?? '',
                                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 18),
                                              Row(
                                                children: [
                                                  _buildStat('关注', merchant!["follow"]?.toString() ?? '0'),
                                                  const SizedBox(width: 18),
                                                  _buildStat('粉丝', merchant!["fans"]?.toString() ?? '0'),
                                                  const SizedBox(width: 18),
                                                  _buildStat('获赞', merchant!["likes"]?.toString() ?? '0'),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 收起时的小头像
                              Positioned(
                                top: statusBarHeight + (kToolbarHeight - 40) / 2,
                                left: (constraints.maxWidth / 2) - 20,
                                child: Opacity(
                                  opacity: fade,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: merchant!["image"] != null && merchant!["image"].toString().isNotEmpty
                                        ? Image.network(
                                            merchant!["image"],
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.store, size: 20, color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // 商品标题和列表
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Center(
                            child: Text(
                              '商品',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _products.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(child: Text('暂无商品')),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _products[index];
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
                                childCount: _products.length,
                              ),
                            ),
                          ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ),
                  ],
                ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.white, // product_detail_page.dart 的颜色
              foregroundColor: Colors.black, // product_detail_page.dart 的颜色
              shape: const CircleBorder(),
              mini: true, // 缩小按钮
              child: Column( // 模拟 product_detail_page.dart 的图标
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 2, color: Colors.black),
                  const Icon(
                    Icons.arrow_upward,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildStat(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
