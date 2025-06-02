import 'package:flutter/material.dart';

import '../models/product_vo.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductVO product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _tabIndex = 0;
  final List<String> _tabs = ['商品', '详情', '推荐'];

  @override
  Widget build(BuildContext context) {
    // 搜索栏高度、标签栏高度、大图高度
    const double searchBarHeight = 56.0;
    const double tabBarHeight = 48.0;
    const double imageHeight = 300.0;

    // 折叠后只剩下“搜索栏+标签栏”时的高度
    final double minExtent = searchBarHeight + tabBarHeight;
    // 完全展开（大图+搜索+标签）时的高度
    final double maxExtent = imageHeight + minExtent;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            // 只让 SliverAppBar 的 expandedHeight = maxExtent
            // SliverAppBar 会自动把状态栏部分算在内，不需要手动加上 `MediaQuery.of(context).padding.top`
            expandedHeight: maxExtent,
            // 折叠后高度 = minExtent
            collapsedHeight: minExtent,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // 注意：constraints.maxHeight 这里是 SliverAppBar 当前高度（不包括状态栏外的空白）
                final double currentExtent = constraints.maxHeight;
                // 计算“大图区域” 从完全可见到完全折叠时滑动的距离
                final double delta = (maxExtent - currentExtent).clamp(
                  0.0,
                  maxExtent,
                );
                // 以 imageHeight 为分母，得到从 0→1 的 fade 值
                final double fade = (delta / imageHeight).clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // —— 1) 大图部分：滑动时透明度由 1→0 ——
                    Opacity(
                      opacity: 1.0 - fade,
                      child: Image.network(
                        widget.product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // —— 2) 搜索+标签 栏：贴在顶部，从透明→不透明，带阴影 ——
                    //     用 SafeArea 保证不会盖住状态栏
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: fade,
                        child: Container(
                          // 高度只需要 minExtent，再使用 SafeArea 为内部留出状态栏空间
                          height:
                              minExtent + MediaQuery.of(context).padding.top,
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
                                // —— 搜索行 ——
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
                                              () => Navigator.pop(context),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.search,
                                          color: Colors.black,
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
                                        // —— 改为收藏和转发按钮 ——
                                        IconButton(
                                          icon: const Icon(
                                            Icons.star_border,
                                            color: Colors.black,
                                          ),
                                          onPressed: () {
                                            // TODO: 收藏逻辑
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.share,
                                            color: Colors.black,
                                          ),
                                          onPressed: () {
                                            // TODO: 转发逻辑
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // —— 标签导航行 ——
                                Container(
                                  height: tabBarHeight,
                                  color: Colors.white,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(_tabs.length, (
                                      index,
                                    ) {
                                      final bool selected = index == _tabIndex;
                                      return GestureDetector(
                                        onTap:
                                            () => setState(
                                              () => _tabIndex = index,
                                            ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _tabs[index],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    selected
                                                        ? Colors.red
                                                        : Colors.black,
                                                fontWeight:
                                                    selected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                            if (selected)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                height: 2,
                                                width: 40,
                                                color: Colors.red,
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
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

          // ————————————
          // 下方的商品详情内容保持原样
          // ————————————
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 价格 + 已售人数
                  Row(
                    children: [
                      Text(
                        '¥ ${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.payers.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 活动文案
                  Text(
                    widget.product.activity,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  // 名称
                  Text(
                    widget.product.name,
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '退货包运费',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 承诺 48 小时内发货
                  Row(
                    children: const [
                      Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '承诺48小时内发货，晚发必赔',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 退货包运费 升级版急速退款 假一赔十
                  Row(
                    children: const [
                      Icon(Icons.verified, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '退货包运费  升级版急速退款  假一赔十',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 占位：10 个占位组件
                  for (int i = 0; i < 10; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
