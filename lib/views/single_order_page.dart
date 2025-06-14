// views/single_order_page.dart

import 'package:flutter/material.dart';
import '../models/orders_create_ro.dart';
import '../models/delivery_address_vo.dart';
import '../models/delivery_address_save_ro.dart';
import '../models/delivery_address_update_ro.dart';
import '../services/api_service.dart';

class SingleOrderPage extends StatefulWidget {
  final OrdersCreateRO order;
  final String productName;
  final String productImage;
  final List<String> productAttributes;

  const SingleOrderPage({
    Key? key,
    required this.order,
    required this.productName,
    required this.productImage,
    required this.productAttributes,
  }) : super(key: key);

  @override
  _SingleOrderPageState createState() => _SingleOrderPageState();
}

class _SingleOrderPageState extends State<SingleOrderPage> {
  bool _isLoading = false;
  String? _errorMessage;
  int? _createdOrderId;
  late int _uid;
  List<DeliveryAddressVO> _addresses = [];
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      // 取出 uid
      final auth = await ApiService.getAuthObject();
      _uid = int.parse(auth['id'] as String);

      // 1) 创建订单
      final orderData = await ApiService.postApi(
        '/api/orders/create-orders',
        data: widget.order.toJson(),
      );
      if (orderData is num) {
        _createdOrderId = orderData.toInt();
      } else if (orderData is String) {
        _createdOrderId = int.tryParse(orderData);
      }

      // 2) 查询用户所有地址
      final addrList = await ApiService.getApi(
        '/api/address/get-all-address',
        queryParameters: {'uid': _uid.toString()},
      );
      if (addrList is List) {
        _addresses = addrList
            .map((e) => DeliveryAddressVO.fromJson(e as Map<String, dynamic>))
            .toList();
        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first.did;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openAddressManager() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('地址管理'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _addresses.length,
                    itemBuilder: (c, i) {
                      final addr = _addresses[i];
                      return ListTile(
                        title: Text('${addr.name}  ${addr.phone}'),
                        subtitle: Text(addr.address),
                        selected: addr.did == _selectedAddressId,
                        onTap: () async {
                          // 更新订单的地址
                          if (_createdOrderId != null) {
                            await ApiService.postApi(
                              '/api/orders/update-address?oid=$_createdOrderId&did=${addr.did}',
                            );
                          }
                          setModalState(() => _selectedAddressId = addr.did);
                          Navigator.of(ctx).pop();
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditAddress(addr, setModalState),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteAddress(addr.did, setModalState),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showAddAddress(setModalState),
                  child: const Text('添加地址'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddress(void Function(void Function()) setModalState) {
    String name = '', phone = '', address = '';
    int sex = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加地址'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '姓名'),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '电话'),
                onChanged: (v) => phone = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '地址'),
                onChanged: (v) => address = v,
              ),
              DropdownButtonFormField<int>(
                value: sex,
                decoration: const InputDecoration(labelText: '性别'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('男')),
                  DropdownMenuItem(value: 2, child: Text('女')),
                ],
                onChanged: (v) => sex = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final ro = DeliveryAddressSaveRO(
                name: name,
                sex: sex,
                phone: phone,
                address: address,
                uid: _uid,
              );
              final data = await ApiService.postApi(
                '/api/address/save-address',
                data: ro.toJson(),
              );
              if (data is num) {
                final newDid = data.toInt();
                setModalState(() {
                  _addresses.add(DeliveryAddressVO(
                    did: newDid,
                    name: name,
                    sex: sex,
                    phone: phone,
                    address: address,
                  ));
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditAddress(
      DeliveryAddressVO addr, void Function(void Function()) setModalState) {
    String name = addr.name, phone = addr.phone, address = addr.address;
    int sex = addr.sex;
    final ctrName = TextEditingController(text: name);
    final ctrPhone = TextEditingController(text: phone);
    final ctrAddr = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑地址'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: ctrName,
                decoration: const InputDecoration(labelText: '姓名'),
                onChanged: (v) => name = v,
              ),
              TextField(
                controller: ctrPhone,
                decoration: const InputDecoration(labelText: '电话'),
                onChanged: (v) => phone = v,
              ),
              TextField(
                controller: ctrAddr,
                decoration: const InputDecoration(labelText: '地址'),
                onChanged: (v) => address = v,
              ),
              DropdownButtonFormField<int>(
                value: sex,
                decoration: const InputDecoration(labelText: '性别'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('男')),
                  DropdownMenuItem(value: 2, child: Text('女')),
                ],
                onChanged: (v) => sex = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final ro = DeliveryAddressUpdateRO(
                did: addr.did,
                name: name,
                sex: sex,
                phone: phone,
                address: address,
                uid: _uid,
              );
              await ApiService.postApi(
                '/api/address/update-address',
                data: ro.toJson(),
              );
              setModalState(() {
                final idx = _addresses.indexWhere((e) => e.did == addr.did);
                _addresses[idx] = DeliveryAddressVO(
                  did: addr.did,
                  name: name,
                  sex: sex,
                  phone: phone,
                  address: address,
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(
      int did, void Function(void Function()) setModalState) async {
    await ApiService.postApi(
      '/api/address/remove-address',
      data: {'did': did},
    );
    setModalState(() {
      _addresses.removeWhere((e) => e.did == did);
      if (_selectedAddressId == did) {
        _selectedAddressId = _addresses.isNotEmpty ? _addresses.first.did : null;
      }
    });
  }

  void _onPay() {
    // TODO: 用 _createdOrderId 和 _selectedAddressId 调用支付逻辑
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('确认订单'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败：$_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initData,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  '确认订单',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _addresses.isEmpty ? null : _openAddressManager,
              child: _addresses.isEmpty
                  ? const Text(
                '暂无地址信息，请先添加地址',
                style: TextStyle(fontSize: 16, color: Colors.red),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_addresses.first.name}  ${_addresses.first.phone}',

                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _addresses.first.address,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '商品信息：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(widget.productImage),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.productAttributes.join(', '),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${widget.order.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '数量：${widget.order.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '总价：¥${(widget.order.price * widget.order.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: (_selectedAddressId == null) ? null : _onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('立即支付'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
