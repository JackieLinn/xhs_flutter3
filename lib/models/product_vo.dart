/// 对应后端的 ProductVO
class ProductVO {
  final int id;
  final String name;
  final String image;
  final String activity;
  final double price;
  final int payers;

  ProductVO({
    required this.id,
    required this.name,
    required this.image,
    required this.activity,
    required this.price,
    required this.payers,
  });

  /// 从 JSON Map 解析出一个 ProductVO
  factory ProductVO.fromJson(Map<String, dynamic> json) {
    return ProductVO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      image: json['image'] as String,
      activity: json['activity'] as String,
      price: (json['price'] as num).toDouble(),
      payers: (json['payers'] as num).toInt(),
    );
  }
}
