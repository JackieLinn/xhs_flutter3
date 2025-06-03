class MerchantVO {
  final int id;
  final String name;
  final String image;
  final int fans;
  final int sold;

  MerchantVO({
    required this.id,
    required this.name,
    required this.image,
    required this.fans,
    required this.sold,
  });

  factory MerchantVO.fromJson(Map<String, dynamic> json) {
    return MerchantVO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      image: json['image'] as String,
      fans: (json['fans'] as num).toInt(),
      sold: (json['sold'] as num).toInt(),
    );
  }
}
