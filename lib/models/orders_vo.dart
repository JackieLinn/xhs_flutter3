import 'package:xhs/models/cart_vo.dart';

class OrdersVO {
  final int oid;
  final CartVO cartVO;
  final DateTime date;
  final double price;
  final int status;

  OrdersVO({
    required this.oid,
    required this.cartVO,
    required this.date,
    required this.price,
    required this.status,
  });

  factory OrdersVO.fromJson(Map<String, dynamic> json) {
    return OrdersVO(
      oid: (json['oid'] as num).toInt(),
      cartVO: CartVO.fromJson(json['cartVO'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
      status: (json['status'] as num).toInt(),
    );
  }
} 