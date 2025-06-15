import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xhs/models/orders_vo.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../models/payment_ro.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  int? _uid;
  bool _isLoading = true;
  String? _errorMsg;
  int _payType = 1; // 1: 支付宝, 2: 微信, Default to Alipay

  List<OrdersVO> _unpaidOrders = [];
  List<OrdersVO> _paidOrders = [];

  int? _selectedUnpaidOrderId; // 记录选中的未支付订单ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final auth = await ApiService.getAuthObject();
      _uid = int.parse(auth['id'] as String);
      await _loadOrders(0); // Load unpaid orders initially
      await _loadOrders(1); // Load paid orders
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders(int status) async {
    if (_uid == null) return;
    try {
      final rawData = await ApiService.getApi(
        '/api/orders/get-orders-list',
        queryParameters: {'uid': _uid.toString(), 'status': status.toString()},
      );
      final List<dynamic> dataList = rawData as List<dynamic>;
      final orders = dataList.map((e) => OrdersVO.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        if (status == 0) {
          _unpaidOrders = orders;
          if (_unpaidOrders.isNotEmpty) {
            _selectedUnpaidOrderId = _unpaidOrders.first.oid; // Select the first unpaid order by default
          }
        } else {
          _paidOrders = orders;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载订单失败：$e')),
        );
      }
      setState(() {
        _errorMsg = '加载订单失败：$e';
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Reload data when tab changes if needed, but we already load both
      // You could add specific reload logic if data is very dynamic
    }
  }

  // Payment logic from single_order_page.dart
  void _onPay(OrdersVO order) async {
    if (_uid == null) {
      // This should ideally not happen if _initData runs successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户ID未获取到，请重试')),
      );
      return;
    }

    final parentContext = context;

    await showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        int tempPayType = _payType;
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => tempPayType = 1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: Image.asset(
                                  'images/alipay.png',
                                  width: 360,
                                  height: 96,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Radio<int>(
                                value: 1,
                                groupValue: tempPayType,
                                onChanged: (v) => setState(() => tempPayType = v!),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => tempPayType = 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: Image.asset(
                                  'images/wechat.png',
                                  width: 360,
                                  height: 96,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Radio<int>(
                                value: 2,
                                groupValue: tempPayType,
                                onChanged: (v) => setState(() => tempPayType = v!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('立即支付'),
                      onPressed: () async {
                        Navigator.pop(sheetContext); // Pop bottom sheet
                        setState(() {
                          _payType = tempPayType; // Update the state's _payType
                        });

                        String? errorMsg;
                        try {
                          final ro = PaymentRO(uid: _uid!, oid: order.oid); // Use current order's OID
                          await ApiService.postApi(
                            '/api/orders/payment',
                            data: ro.toJson(),
                          );
                          if (!mounted) return;
                          await showDialog(
                            context: parentContext,
                            builder: (ctx2) => AlertDialog(
                              title: const Text('支付成功'),
                              content: const Text('您的订单已支付成功！'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx2).pop(),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                          if (!mounted) return;
                          // After successful payment, reload orders and navigate
                          await _initData(); // Reload orders to update lists
                          Navigator.of(parentContext).pushNamedAndRemoveUntil(
                            '/home',
                            (route) => false,
                            arguments: {'initialIndex': 3},
                          );
                          return;
                        } catch (e) {
                          errorMsg = '支付失败：$e';
                        }
                        if (errorMsg != null && mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        }
                      },
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48.0), // AppBar height + TabBar height
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
                '我的订单',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.black,
            tabs: const [
              Tab(text: '未支付'),
              Tab(text: '已支付'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('加载失败：$_errorMsg'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(_unpaidOrders, isUnpaid: true),
                    _buildOrderList(_paidOrders, isUnpaid: false),
                  ],
                ),
    );
  }

  Widget _buildOrderList(List<OrdersVO> orders, {required bool isUnpaid}) {
    if (orders.isEmpty) {
      return Center(child: Text(isUnpaid ? '暂无未支付订单' : '暂无已支付订单'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '订单号: ${order.oid}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isUnpaid ? '未支付' : '已支付',
                      style: TextStyle(
                        color: isUnpaid ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUnpaid)
                      Radio<int>(
                        value: order.oid,
                        groupValue: _selectedUnpaidOrderId,
                        onChanged: (value) {
                          setState(() {
                            _selectedUnpaidOrderId = value;
                          });
                        },
                      ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(order.cartVO.image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.cartVO.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.cartVO.attributes.join('，'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '单价: ¥${order.cartVO.price.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '数量: ${order.cartVO.quantity}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '总价: ¥${order.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    if (isUnpaid && _selectedUnpaidOrderId == order.oid)
                      ElevatedButton(
                        onPressed: () => _onPay(order), // Payment logic placeholder
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('去支付'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '下单时间: ${DateFormat('yyyy-MM-dd').format(order.date.toLocal())}', // Format date
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
