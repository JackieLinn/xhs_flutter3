import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../components/product_card.dart';
import '../models/cart_list_one_ro.dart';
import '../models/merchant_vo.dart';
import '../models/option_vo.dart';
import '../models/product_selection_vo.dart';
import '../models/product_vo.dart';
import '../services/api_service.dart';
import './cart_page.dart';
import './merchant_page.dart';
import './single_cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductVO product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Future<List<dynamic>>? _futureData;
  Future<List<ProductVO>>? _futureRecommends;
  late PageController _pageController;

  // 直接在声明时初始化 ScrollController
  final ScrollController _scrollController = ScrollController();

  // 用于保存异步获取到的商家信息
  Future<MerchantVO>? _futureMerchant;
  MerchantVO? _merchant;

  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // 当前激活的子导航索引：0=商品,1=图文详情,2=推荐
  int _tabIndex = 0;
  final List<String> _tabs = ['商品', '详情', '推荐'];

  // 是否显示“回到顶部”按钮
  bool _showBackToTop = false;

  // 用于标记“图文详情”和“推荐商品”分隔条的位置
  final GlobalKey _detailDividerKey = GlobalKey();
  final GlobalKey _recommendDividerKey = GlobalKey();

  // ========== 以下是为了在 _showSelectionSheet 内跨作用域跟踪用户选择后数据 ==========
  int _lastQty = 1;
  double _lastUnitPrice = 0.0;
  List<int> _lastSelectedOptionIds = [];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    // 在 initState 中添加滚动监听
    _scrollController.addListener(_onScroll);

    // 初始化商品详情和详情图的 Future
    _futureData = Future.wait([
      _fetchProductDetail(),
      _fetchDetailImages(),
    ]).then((list) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoPlay(list[1] as List<String>);
      });
      return list;
    });

    // 在 initState 中给 _futureRecommends 赋值
    _futureRecommends = _fetchRecommendProducts();

    // **新增：在 initState 中触发商家数据的获取**
    _futureMerchant = _fetchMerchantByPid(widget.product.id);
    _futureMerchant!.then((m) {
      setState(() {
        _merchant = m;
      });
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose(); // 一定要 dispose
    super.dispose();
  }

  /// 异步获取商家信息，接口：/api/merchant/get-merchant-by-pid?pid=xxx
  Future<MerchantVO> _fetchMerchantByPid(int pid) async {
    final rawData = await ApiService.getApi(
      '/api/merchant/get-merchant-by-pid',
      queryParameters: {'pid': pid.toString()},
    );
    return MerchantVO.fromJson(rawData as Map<String, dynamic>);
  }

  /// 异步获取商品选择信息，接口：/api/variant/get-product-selection?pid=xxx
  Future<ProductSelectionVO> _fetchProductSelection(int pid) async {
    final rawData = await ApiService.getApi(
      '/api/variant/get-product-selection',
      queryParameters: {'pid': pid.toString()},
    );
    // 假设后端直接返回 { data: {...} }，这里简化为 rawData 就是 ProductSelectionVO 对应的 JSON
    return ProductSelectionVO.fromJson(rawData as Map<String, dynamic>);
  }

  /// 滚动监听：计算“图文详情”和“推荐商品”分隔条相对于屏幕的位置，
  /// 来决定当前应该高亮哪个子导航，以及是否显示“回到顶部”按钮。
  void _onScroll() {
    const double searchBarHeight = 56.0;
    const double tabBarHeight = 48.0;
    final double pinnedBarHeight =
        MediaQuery.of(context).padding.top + searchBarHeight + tabBarHeight;

    double _widgetGlobalY(GlobalKey key) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        return renderObject.localToGlobal(Offset.zero).dy;
      }
      return double.infinity;
    }

    final detailY = _widgetGlobalY(_detailDividerKey);
    final recommendY = _widgetGlobalY(_recommendDividerKey);

    int newIndex;
    if (recommendY <= pinnedBarHeight) {
      newIndex = 2;
    } else if (detailY <= pinnedBarHeight) {
      newIndex = 1;
    } else {
      newIndex = 0;
    }

    final bool shouldShowBack = detailY <= pinnedBarHeight;

    if (newIndex != _tabIndex || shouldShowBack != _showBackToTop) {
      setState(() {
        _tabIndex = newIndex;
        _showBackToTop = shouldShowBack;
      });
    }
  }

  /// 点击子导航时，滚动到对应位置
  void _onTabTap(int index) {
    double targetOffset = 0;
    const double searchBarHeight = 56.0;
    const double tabBarHeight = 48.0;

    if (index == 0) {
      targetOffset = 0;
    } else if (index == 1) {
      final detailBox = _detailDividerKey.currentContext?.findRenderObject();
      if (detailBox is RenderBox) {
        final detailOffset = detailBox.localToGlobal(Offset.zero).dy;
        targetOffset =
            _scrollController.offset +
            (detailOffset -
                (MediaQuery.of(context).padding.top +
                    searchBarHeight +
                    tabBarHeight));
      }
    } else {
      final recommendBox =
          _recommendDividerKey.currentContext?.findRenderObject();
      if (recommendBox is RenderBox) {
        final recOffset = recommendBox.localToGlobal(Offset.zero).dy;
        targetOffset =
            _scrollController.offset +
            (recOffset -
                (MediaQuery.of(context).padding.top +
                    searchBarHeight +
                    tabBarHeight));
      }
    }

    final clamped = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 点击“回到顶部”按钮时，滚动到最顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startAutoPlay(List<String> detailImages) {
    final carouselLength = 1 + detailImages.take(2).length;
    if (carouselLength < 2) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % carouselLength;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<ProductVO> _fetchProductDetail() async {
    final rawData = await ApiService.getApi(
      '/api/product/get-product-by-id',
      queryParameters: {'id': widget.product.id.toString()},
    );
    return ProductVO.fromJson(rawData);
  }

  Future<List<String>> _fetchDetailImages() async {
    final rawData = await ApiService.getApi(
      '/api/images/get-images-by-pid',
      queryParameters: {'pid': widget.product.id.toString()},
    );
    final List<dynamic> dataList = rawData as List<dynamic>;
    return dataList.map((e) => e as String).toList();
  }

  Future<List<ProductVO>> _fetchRecommendProducts() async {
    final rawData = await ApiService.getApi(
      '/api/product/get-recommend-products',
    );
    final List<dynamic> dataList = rawData as List<dynamic>;
    return dataList
        .map((e) => ProductVO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 显示底部选择面板——加入购物车 / 立即购买 都调用它
  void _showSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // 顶部“拖拽小拉手”
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 右上角“X”关闭按钮
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // 头部商品信息：缩略图 + 名称 + 退货提示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Image.network(
                          widget.product.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '7天无理由退货，退货包运费',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // 异步加载：价格 + 所有分类 + 数量选择
                  Expanded(
                    child: FutureBuilder<ProductSelectionVO>(
                      future: _fetchProductSelection(widget.product.id),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError || snap.data == null) {
                          return const Center(child: Text('加载失败'));
                        }
                        final selection = snap.data!;

                        // 初始化：所有分类的选中项
                        final Map<String, OptionVO> selectedOptions = {};
                        for (var categoryMap in selection.categories) {
                          categoryMap.forEach((categoryName, optionList) {
                            selectedOptions[categoryName] = optionList.first;
                          });
                        }

                        int qty = 1; // 默认数量
                        double unitPrice = selection.price; // 单价，后续点击分类时动态更新

                        // 同时初始化外部跟踪变量
                        _lastQty = qty;
                        _lastUnitPrice = unitPrice;
                        _lastSelectedOptionIds =
                            selectedOptions.values.map((o) => o.id).toList();

                        return StatefulBuilder(
                          builder: (context, setState) {
                            // Helper: 组合所有选中的 optionId 列表
                            List<int> getSelectedOptionIds() {
                              return selectedOptions.values
                                  .map((opt) => opt.id)
                                  .toList();
                            }

                            // Helper: 当某个分类选项被点击时，调用后端 calculate-price 接口
                            Future<void> _refreshUnitPrice() async {
                              try {
                                final List<int> selectedIds =
                                    getSelectedOptionIds();
                                final String joinedIds = selectedIds.join(',');

                                final raw = await ApiService.getApi(
                                  '/api/variant/calculate-price',
                                  queryParameters: {
                                    'pid': widget.product.id.toString(),
                                    'optionIds': joinedIds,
                                  },
                                );
                                final double newPrice = (raw as num).toDouble();
                                setState(() {
                                  unitPrice = newPrice;

                                  // 同步更新外部跟踪价格
                                  _lastUnitPrice = newPrice;
                                });
                              } catch (e) {
                                // 出错时保留原单价
                              }
                            }

                            return SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 顶部价格：用最新的单价乘数量
                                  Text(
                                    '¥ ${(unitPrice * qty).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // 遍历所有分类
                                  for (var categoryMap
                                      in selection.categories) ...[
                                    for (var entry in categoryMap.entries) ...[
                                      // 分类名称
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // 渲染该分类下所有选项
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            entry.value.map((opt) {
                                              final bool isSelected =
                                                  (selectedOptions[entry.key]
                                                          ?.id ==
                                                      opt.id);
                                              return GestureDetector(
                                                onTap: () async {
                                                  if (!isSelected) {
                                                    setState(() {
                                                      selectedOptions[entry
                                                              .key] =
                                                          opt;
                                                    });
                                                    await _refreshUnitPrice();

                                                    // 每次选中改变，都更新外部跟踪选项列表
                                                    _lastSelectedOptionIds =
                                                        getSelectedOptionIds();
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? Colors.red
                                                            : Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          isSelected
                                                              ? Colors.red
                                                              : Colors.grey,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    opt.content,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ],

                                  // 数量选择器
                                  Text(
                                    '数量',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // 减号按钮
                                      GestureDetector(
                                        onTap: () {
                                          if (qty > 1) {
                                            setState(() {
                                              qty--;
                                              _lastQty = qty; // 更新外部跟踪数量
                                            });
                                          }
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 加号按钮
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            qty++;
                                            _lastQty = qty; // 更新外部跟踪数量
                                          });
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 底部“确定”按钮（固定区域），需要传递 CartListOneRO 给 SingleCartPage
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () async {
                        // *************** 在这里取出 uid ****************
                        const _storage = FlutterSecureStorage();
                        final rawAuth = await _storage.read(
                          key: 'access_token',
                        );
                        if (rawAuth == null) {
                          // 如果未登录，可自行决定提示或跳到登录页
                          return;
                        }
                        final authObj =
                            jsonDecode(rawAuth) as Map<String, dynamic>;
                        final int uid = int.parse(authObj['id'] as String);

                        // pid = 当前商品ID
                        final int pid = widget.product.id;

                        // 组装 CartListOneRO
                        final cartRO = CartListOneRO(
                          uid: uid,
                          pid: pid,
                          price: _lastUnitPrice, // 单价（不乘数量）
                          quantity: _lastQty,
                          aoids: _lastSelectedOptionIds,
                        );

                        Navigator.of(context).pop(); // 关闭底部面板
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => SingleCartPage(cartItem: cartRO),
                          ),
                        );
                      },
                      child: const Text(
                        '确定',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 56.0;
    const double tabBarHeight = 48.0;
    const double carouselHeight = 300.0;
    final double minExtent = searchBarHeight + tabBarHeight;
    final double maxExtent = carouselHeight + minExtent;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  _futureData == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载失败：${snapshot.error}'));
              }

              final product = snapshot.data![0] as ProductVO;
              final detailImages = snapshot.data![1] as List<String>;

              final carouselImages = [product.image, ...detailImages.take(2)];

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ========== SliverAppBar ==========
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    expandedHeight: maxExtent,
                    collapsedHeight: minExtent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        final double currentExtent = constraints.maxHeight;
                        final double delta = (maxExtent - currentExtent).clamp(
                          0.0,
                          maxExtent,
                        );
                        final double fade = (delta / carouselHeight).clamp(
                          0.0,
                          1.0,
                        );

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // 轮播图 (PageView) 自动播放
                            Opacity(
                              opacity: 1.0 - fade,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: carouselImages.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    carouselImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                },
                              ),
                            ),

                            // 搜索栏 + 子导航栏（仅折叠后显示）
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Opacity(
                                opacity: fade,
                                child: Container(
                                  height:
                                      minExtent +
                                      MediaQuery.of(context).padding.top,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SafeArea(
                                    bottom: false,
                                    child: Column(
                                      children: [
                                        // 搜索行
                                        SizedBox(
                                          height: searchBarHeight,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.arrow_back,
                                                    color: Colors.black,
                                                  ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.search,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                      hintText: '搜你想要的商品',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.star_border,
                                                    color: Colors.black,
                                                  ),
                                                  onPressed: () {},
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.share,
                                                    color: Colors.black,
                                                  ),
                                                  onPressed: () {},
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 子导航栏：只在折叠后可见
                                        SizedBox(
                                          height: tabBarHeight,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: List.generate(
                                              _tabs.length,
                                              (index) {
                                                final bool selected =
                                                    index == _tabIndex;
                                                return GestureDetector(
                                                  onTap: () => _onTabTap(index),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        _tabs[index],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              selected
                                                                  ? Colors.red
                                                                  : Colors
                                                                      .black,
                                                          fontWeight:
                                                              selected
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                        ),
                                                      ),
                                                      if (selected)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.only(
                                                                top: 4,
                                                              ),
                                                          height: 2,
                                                          width: 40,
                                                          color: Colors.red,
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ========== 商品详情 + 商家信息 + 详情图等内容 ==========
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 带左右 16 padding 的商品信息
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8.0,
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 价格 + 已售
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '¥ ${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '已售 ${product.payers} 件',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 活动文案
                              Text(
                                product.activity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 商品名称
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 退货包运费
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '退货包运费',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // IP 信息
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'IP: 云南昆明',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 承诺 48 小时内发货
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '承诺48小时内发货，晚发必赔',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 认证图标 + 其他保障
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '退货包运费  升级版急速退款  假一赔十',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 新增活动行
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '最高送500元，全店通用更优惠',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 2. 商家信息模块（上下灰色分隔 + 相同左右 padding）
                        Container(height: 8, color: Colors.grey.shade300),
                        FutureBuilder<MerchantVO>(
                          future: _futureMerchant,
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snap.hasError || snap.data == null) {
                              return const SizedBox();
                            }
                            final merchant = snap.data!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage(
                                        merchant.image,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          merchant.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '粉丝 ${merchant.fans}   已售 ${merchant.sold}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              height: 20,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              decoration: const BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                '旗舰店',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 20,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topRight: Radius.circular(
                                                        4,
                                                      ),
                                                      bottomRight:
                                                          Radius.circular(4),
                                                    ),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                '4.61分',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      if (_merchant != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (c) => MerchantPage(
                                                  mid: merchant.id,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '进店',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // 3. “图文详情”分隔条 (带 GlobalKey)
                        Container(
                          key: _detailDividerKey,
                          height: 40,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Text(
                            '—— 图文详情 ——',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 4. 全屏宽度展示的详情图片列表
                        for (final imgUrl in detailImages)
                          Image.network(
                            imgUrl,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.cover,
                          ),

                        // 5. “推荐商品”分隔条 (带 GlobalKey)
                        Container(
                          key: _recommendDividerKey,
                          height: 40,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Text(
                            '—— 推荐商品 ——',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ========= 推荐商品列表 =========
                  SliverToBoxAdapter(
                    child:
                        _futureRecommends == null
                            ? const SizedBox()
                            : FutureBuilder<List<ProductVO>>(
                              future: _futureRecommends,
                              builder: (context, snap) {
                                if (snap.connectionState !=
                                    ConnectionState.done) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snap.hasError) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Center(child: Text('加载失败')),
                                  );
                                }
                                final recommends = snap.data ?? [];
                                if (recommends.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Center(child: Text('暂无推荐商品')),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 8.0,
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 0.65,
                                        ),
                                    itemCount: recommends.length,
                                    itemBuilder: (context, index) {
                                      final item = recommends[index];
                                      return ProductCard(
                                        image: item.image,
                                        name: item.name,
                                        activity: item.activity,
                                        price: item.price,
                                        payers: item.payers,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (c) => ProductDetailPage(
                                                    product: item,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          ),

          // “回到顶部”按钮：当 _showBackToTop 为 true 时显示
          if (_showBackToTop)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 6.0,
                shape: const CircleBorder(),
                mini: true,
                onPressed: _scrollToTop,
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
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 底部“店铺”图标 + 文本，与上方“进店”逻辑一致
                        GestureDetector(
                          onTap: () {
                            if (_merchant != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (c) => MerchantPage(mid: _merchant!.id),
                                ),
                              );
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage:
                                    _merchant != null
                                        ? NetworkImage(_merchant!.image)
                                        : null,
                                backgroundColor:
                                    _merchant == null ? Colors.grey : null,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '店铺',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.headset_mic,
                              size: 24,
                              color: Colors.grey.shade800,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '客服',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const CartPage(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 24,
                                color: Colors.grey.shade800,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '购物车',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  flex: 7,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.red,
                    ),
                    child: Row(
                      children: [
                        // “加入购物车” 包裹时机——弹出底部选择面板
                        Expanded(
                          child: GestureDetector(
                            onTap: _showSelectionSheet,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '加入购物车',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // “立即购买” 也弹出同一个底部面板
                        Expanded(
                          child: GestureDetector(
                            onTap: _showSelectionSheet,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '立即购买',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
