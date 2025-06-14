class OrdersCreateRO {
  final int cid;
  final int uid;
  final double price;
  final int quantity;

  OrdersCreateRO({
    required this.cid,
    required this.uid,
    required this.price,
    required this.quantity,
  });

  /// 如果以后需要从 JSON 构造订单对象
  factory OrdersCreateRO.fromJson(Map<String, dynamic> json) {
    return OrdersCreateRO(
      cid: json['cid'] as int,
      uid: json['uid'] as int,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  /// 将 OrdersCreateRO 转为 JSON，用于创建订单请求
  Map<String, dynamic> toJson() {
    return {'cid': cid, 'uid': uid, 'price': price, 'quantity': quantity};
  }
}
