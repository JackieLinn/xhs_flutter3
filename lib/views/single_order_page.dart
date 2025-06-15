import 'package:flutter/material.dart';
import 'package:xhs/models/payment_ro.dart';
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
  DeliveryAddressVO? _selectedAddress;

  int _payType = 1; // 1: 支付宝, 2: 微信

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = await ApiService.getAuthObject();
      _uid = int.parse(auth['id'] as String);

      final resp = await ApiService.postApi(
        '/api/orders/create-orders',
        data: widget.order.toJson(),
      );
      if (resp is num) {
        _createdOrderId = resp.toInt();
      } else if (resp is String) {
        _createdOrderId = int.tryParse(resp);
      }

      await _loadAddresses();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    final data = await ApiService.getApi(
      '/api/address/get-all-address',
      queryParameters: {'uid': _uid.toString()},
    );

    final list = <DeliveryAddressVO>[];
    if (data is List && data.isNotEmpty) {
      for (var item in data) {
        try {
          list.add(DeliveryAddressVO.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('解析地址失败，已跳过：$e');
        }
      }
    }

    setState(() {
      _addresses = list;
      if (list.isNotEmpty) {
        _selectedAddressId = list.first.id;
        _selectedAddress = list.first;
      } else {
        _selectedAddressId = null;
        _selectedAddress = null;
      }
    });
  }

  Future<void> _loadSelectedAddress() async {
    if (_selectedAddressId == null) return;

    final data = await ApiService.getApi(
      '/api/address/get-address-by-id',
      queryParameters: {'did': _selectedAddressId.toString()},
    );

    if (data is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = DeliveryAddressVO.fromJson(data);
      });
    }
  }

  Future<void> _openAddressManager() async {
    if (_addresses.isEmpty) {
      await _addNewAddress();
      return;
    }

    await _loadAddresses();

    final did = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddressManagerDialog(
        addresses: _addresses,
        uid: _uid,
      ),
    );

    if (did != null && _createdOrderId != null) {
      await ApiService.postApi(
        '/api/orders/update-address?oid=$_createdOrderId&did=$did',
      );

      setState(() {
        _selectedAddressId = did;
      });

      await _loadSelectedAddress();
    }
  }

  Future<void> _addNewAddress() async {
    String name = '', phone = '', addr = '';
    int sex = 1;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              onChanged: (v) => addr = v,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (name.isEmpty || phone.isEmpty || addr.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息')),
                );
                return;
              }

              final ro = DeliveryAddressSaveRO(
                name: name,
                sex: sex,
                phone: phone,
                address: addr,
                uid: _uid,
              );

              await ApiService.postApi('/api/address/save-address', data: ro.toJson());
              Navigator.pop(ctx);
              await _loadAddresses();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _onPay() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择收货地址')),
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
                        Navigator.pop(sheetContext);
                        setState(() {
                          _payType = tempPayType;
                        });
                        String? errorMsg;
                        try {
                          final ro = PaymentRO(uid: _uid, oid: _createdOrderId!);
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
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
                const SizedBox(width: 60),
              ],
            ),
          ),
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
              const SizedBox(width: 60),
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
              onTap: _openAddressManager,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedAddress == null
                    ? const Row(
                  children: [
                    Icon(Icons.add_location_alt, color: Colors.red),
                    SizedBox(width: 8),
                    Text('添加收货地址', style: TextStyle(color: Colors.red)),
                  ],
                )
                    : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedAddress!.name}${_selectedAddress!.sex == 1 ? '先生' : '女士'}  ${_selectedAddress!.phone}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(_selectedAddress!.address),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('商品信息：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      ),
                      const SizedBox(height: 8),
                      Text(widget.productAttributes.join(', ')),
                      const SizedBox(height: 8),
                      Text(
                        '¥${widget.order.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text('数量：${widget.order.quantity}'),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _selectedAddress == null ? null : _onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAddress == null ? Colors.grey : Colors.red,
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

class _AddressManagerDialog extends StatefulWidget {
  final List<DeliveryAddressVO> addresses;
  final int uid;

  const _AddressManagerDialog({
    required this.addresses,
    required this.uid,
    Key? key,
  }) : super(key: key);

  @override
  State<_AddressManagerDialog> createState() => _AddressManagerDialogState();
}

class _AddressManagerDialogState extends State<_AddressManagerDialog> {
  late List<DeliveryAddressVO> _list;

  @override
  void initState() {
    super.initState();
    _list = List.of(widget.addresses);
  }

  Future<void> _reload() async {
    final data = await ApiService.getApi(
      '/api/address/get-all-address',
      queryParameters: {'uid': widget.uid.toString()},
    );

    if (data is List && data.isNotEmpty) {
      setState(() {
        _list = data.map((e) => DeliveryAddressVO.fromJson(e)).toList();
      });
    } else {
      setState(() => _list = []);
    }
  }

  Future<void> _add() async {
    String name = '', phone = '', addr = '';
    int sex = 1;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              onChanged: (v) => addr = v,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (name.isEmpty || phone.isEmpty || addr.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息')),
                );
                return;
              }

              final ro = DeliveryAddressSaveRO(
                name: name,
                sex: sex,
                phone: phone,
                address: addr,
                uid: widget.uid,
              );

              await ApiService.postApi('/api/address/save-address', data: ro.toJson());
              Navigator.pop(ctx);
              await _reload();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(DeliveryAddressVO a) async {
    String name = a.name, phone = a.phone, addr = a.address;
    int sex = a.sex;

    final cN = TextEditingController(text: name);
    final cP = TextEditingController(text: phone);
    final cA = TextEditingController(text: addr);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cN,
              decoration: const InputDecoration(labelText: '姓名'),
              onChanged: (v) => name = v,
            ),
            TextField(
              controller: cP,
              decoration: const InputDecoration(labelText: '电话'),
              onChanged: (v) => phone = v,
            ),
            TextField(
              controller: cA,
              decoration: const InputDecoration(labelText: '地址'),
              onChanged: (v) => addr = v,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (name.isEmpty || phone.isEmpty || addr.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息')),
                );
                return;
              }

              final ro = DeliveryAddressUpdateRO(
                did: a.id,
                name: name,
                sex: sex,
                phone: phone,
                address: addr,
                uid: widget.uid,
              );

              await ApiService.postApi('/api/address/update-address', data: ro.toJson());
              Navigator.pop(ctx);
              await _reload();
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int did) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个地址吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.postApi('/api/address/remove-address?did=$did');
      await _reload();
    }
  }

  @override
  Widget build(BuildContext c) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '地址管理',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(c).size.height * .5,
              ),
              child: ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final a = _list[i];
                  return ListTile(
                    title: Text('${a.name}${a.sex == 1 ? '先生' : '女士'}  ${a.phone}'),
                    subtitle: Text(a.address),
                    onTap: () => Navigator.pop(c, a.id),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _edit(a),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _delete(a.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加地址'),
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
