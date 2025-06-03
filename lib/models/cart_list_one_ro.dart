import 'dart:convert';

/// 对应后端的 CartListOneRO
class CartListOneRO {
  final int uid;
  final int pid;
  final double price;
  final int quantity;
  final List<int> aoids;

  CartListOneRO({
    required this.uid,
    required this.pid,
    required this.price,
    required this.quantity,
    required this.aoids,
  });

  /// 从 JSON 构造
  factory CartListOneRO.fromJson(Map<String, dynamic> json) {
    return CartListOneRO(
      uid: (json['uid'] as num).toInt(),
      pid: (json['pid'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      aoids: (json['aoids'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
    );
  }

  /// 序列化为 JSON（用于向后端 POST）
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'pid': pid,
      'price': price,
      'quantity': quantity,
      'aoids': aoids,
    };
  }

  /// 如果需要把整个对象转为 JSON 字符串
  String toJsonString() => jsonEncode(toJson());
}
