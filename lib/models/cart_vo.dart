class CartVO {
  final int cid; // 购物车 ID
  final String image; // 商品图片 URL
  final String name; // 商品名称
  final List<String> attributes; // 属性列表
  final double price; // 单价
  final int quantity; // 原始后端返回的数量

  CartVO({
    required this.cid,
    required this.image,
    required this.name,
    required this.attributes,
    required this.price,
    required this.quantity,
  });

  factory CartVO.fromJson(Map<String, dynamic> json) {
    return CartVO(
      cid: json['cid'] as int,
      image: json['image'] as String,
      name: json['name'] as String,
      attributes: List<String>.from(json['attributes'] as List<dynamic>),
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}
