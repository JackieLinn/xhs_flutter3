import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'merchant_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    try {
      final rawData = await ApiService.getApi('/api/merchant/get-all-merchants');
      final List<dynamic> dataList = rawData as List<dynamic>;
      setState(() {
        _merchants = dataList.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = '加载失败：$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.grey,
          titleSpacing: 0,
          title: Stack(
            alignment: Alignment.center,
            children: [
              // 返回按钮
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // 居中标题
              const Text(
                '店铺',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(child: Text(_errorMsg!))
              : _merchants.isEmpty
                  ? const Center(child: Text('暂无店铺'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _merchants.length,
                      itemBuilder: (context, index) {
                        final merchant = _merchants[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MerchantPage(mid: merchant['id']),
                              ),
                            );
                          },
                          child: Container(
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
                              child: Row(
                                children: [
                                  // 商家头像
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: merchant['image'] != null && merchant['image'].toString().isNotEmpty
                                        ? Image.network(
                                            merchant['image'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.store, size: 30, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 商家信息
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          merchant['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.people, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${merchant['fans'] ?? 0} 粉丝',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${merchant['sold'] ?? 0} 已售',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 右侧箭头
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
