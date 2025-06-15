class DeliveryAddressVO {
  final int id;
  final String name;
  final int sex;
  final String phone;
  final String address;

  DeliveryAddressVO({
    required this.id,
    required this.name,
    required this.sex,
    required this.phone,
    required this.address,
  });

  factory DeliveryAddressVO.fromJson(Map<String, dynamic> json) {
    // 先校验 id，避免 "null" 解析失败
    final rawId = json['id'];
    if (rawId == null || rawId is! int) {
      throw Exception('DeliveryAddressVO.fromJson: id 无效 -> $rawId');
    }
    return DeliveryAddressVO(
      id: rawId,
      name: json['name'] as String? ?? '',
      sex: json['sex'] as int? ?? 0,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sex': sex,
    'phone': phone,
    'address': address,
  };
}
