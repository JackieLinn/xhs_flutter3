import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../models/product_vo.dart';
import '../components/product_card.dart';
import '../views/product_detail_page.dart';

class MerchantPage extends StatefulWidget {
  final int mid;

  const MerchantPage({super.key, required this.mid});

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  Map<String, dynamic>? merchant;
  List<ProductVO> _products = [];
  bool isLoading = true;
  String? errorMsg;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  double _scrollProgress = 0.0; // 0.0 when expanded, 1.0 when collapsed
  final double _merchantInfoContentHeight = 200.0; // 商家信息内容区域的实际高度 (不含状态栏和 AppBar 高度)

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      // Calculate scroll progress based on how much of the merchant info content has scrolled past
      // This controls the fading of merchant details and the appearance of the collapsed avatar.
      final double progress = (_scrollController.offset / _merchantInfoContentHeight).clamp(0.0, 1.0);
      // Control the visibility of the back-to-top button separately
      final bool shouldShow = _scrollController.offset >= _merchantInfoContentHeight * 0.7; 

      if (progress != _scrollProgress) {
        setState(() {
          _scrollProgress = progress;
        });
      }
      if (shouldShow != _showBackToTopButton) {
        setState(() {
          _showBackToTopButton = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final merchantData = await ApiService.getApi(
        '/api/merchant/get-merchant-by-id',
        queryParameters: {'id': widget.mid.toString()},
      );
      final productRawData = await ApiService.getApi(
        '/api/product/get-products-by-mid',
        queryParameters: {'mid': widget.mid.toString()},
      );
      final List<dynamic> productList = productRawData as List<dynamic>;

      setState(() {
        merchant = merchantData as Map<String, dynamic>;
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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double standardAppBarHeight = kToolbarHeight; // Standard AppBar height (56.0)

    // Total height of the expanded area within the SliverAppBar
    final double expandedAppBarTotalHeight = standardAppBarHeight + _merchantInfoContentHeight + statusBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows content to scroll behind the AppBar area
      backgroundColor: Colors.white, // Set Scaffold background to white
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      expandedHeight: expandedAppBarTotalHeight, // Total height when expanded
                      collapsedHeight: standardAppBarHeight + statusBarHeight, // Standard height for collapsed pinned AppBar
                      pinned: true, // Stays at the top when collapsed
                      backgroundColor: const Color(0xFF512DA8), // Solid background for the collapsed AppBar
                      // Back button now in leading
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Collapsed AppBar Title (Avatar, fades in)
                      centerTitle: true, // Ensures the title is centered
                      title: Opacity(
                        opacity: _scrollProgress, // Fades in as _scrollProgress goes from 0 to 1
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
                      flexibleSpace: FlexibleSpaceBar(
                        background: ClipRect( // IMPORTANT: Clip the background to prevent bleed
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column( // Use a Column to stack elements and control spacing precisely
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: statusBarHeight + standardAppBarHeight - 5), // Precise positioning: moved up 5px
                                Opacity(
                                  opacity: 1.0 - _scrollProgress, // Fades out as _scrollProgress goes from 0 to 1
                                  child: Container(
                                    height: _merchantInfoContentHeight, // Explicit height for content
                                    padding: const EdgeInsets.symmetric(horizontal: 20), // Horizontal padding for merchant info
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min, // Use min to fit content
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start, // Align content to start of column (top)
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
                                            const SizedBox(width: 10),
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
                                        const SizedBox(height: 16), // Keep bottom padding for merchant info content
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Product title and list (white background and shadow)
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Pure white background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, -3), // Top shadow
                            ),
                          ],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // Rounded corners
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Ensure it wraps content tightly
                          children: [
                            // Product title - even further reduced padding
                            const Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 8, 0), // Added top and bottom padding for vertical centering
                              child: Text(
                                '商品',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Product list - reduced vertical padding (already minimal)
                            _products.isEmpty
                                ? const Center(child: Text('暂无商品'))
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Already minimal, keeping it
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.75,
                                      ),
                                      itemBuilder: (context, index) {
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
                                      itemCount: _products.length,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom spacing - ensure it's white and small
                    SliverToBoxAdapter(
                      child: SizedBox(height: MediaQuery.of(context).padding.bottom + 5), // Reduced bottom padding even more
                    ),
                  ],
                ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              mini: true,
              child: Column(
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
