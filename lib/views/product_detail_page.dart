import 'package:flutter/material.dart';

import '../models/product_vo.dart';
import './cart_page.dart'; // 导入购物车页面

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
            expandedHeight: maxExtent,
            collapsedHeight: minExtent,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // constraints.maxHeight 是 SliverAppBar 当前内容高度（不含状态栏外空白）
                final double currentExtent = constraints.maxHeight;
                // 计算“大图区域”滑动时消失的百分比
                final double delta = (maxExtent - currentExtent).clamp(
                  0.0,
                  maxExtent,
                );
                final double fade = (delta / imageHeight).clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // —— 大图部分：滑动时透明度由 1→0 ——
                    Opacity(
                      opacity: 1.0 - fade,
                      child: Image.network(
                        widget.product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // —— 搜索+标签 栏：从顶部出现，带阴影 ——
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: fade,
                        child: Container(
                          // 高度 = minExtent + 状态栏高度
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
                                        // —— 收藏 和 转发 按钮 ——
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
          // 下方商品详情内容（拆分为：带 Padding 的内容 + 全宽图片）
          // ————————————
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 带左右 16 padding 的内容
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
                      // 价格 分居两侧 + 已售xxx件
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥ ${widget.product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '已售 ${widget.product.payers} 件',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 活动文案（红色）
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
                      // 认证图标的退货包运费下面的那一行
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
                      // 新增活动行：图标 + 文本 + 右侧箭头，文字灰色
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // 2. 全屏宽度展示的 5 张图片（去掉左右 padding）
                for (int i = 0; i < 5; i++)
                  Image.network(
                    'https://www.58fuke.com/download/temp/20250531/1748676159_7_eac27167_4ff6_476e_a20e_42793d92a72b.png',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                // 3. 底部留空间
                // const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ————————————
      // 底部固定功能栏
      // ————————————
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
                // —— 左侧三个图标文字区域，占比约 30% ——
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 店铺（圆形图片 + 文字）
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(
                                'https://tcwebchat.sporttery.cn/res/image.html?id=upload/c1302f5f80e7bf80cb7fa6684d79797b&6.png',
                              ),
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
                        // 客服（图标 + 文字）
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
                        // 购物车（图标 + 文字），点击跳转到 CartPage
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

                // —— 右侧两个按钮区域，占比约 70% ——
                Flexible(
                  flex: 7,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.red, // 主要为了配合右侧“立即购买”红底
                    ),
                    child: Row(
                      children: [
                        // 加入购物车（浅红底 + 红色文字）
                        Expanded(
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
                        // 立即购买（红底 + 白色文字）
                        Expanded(
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
