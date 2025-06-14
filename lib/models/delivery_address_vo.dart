class DeliveryAddressVO {
  final int did;
  final String name;
  final int sex;
  final String phone;
  final String address;

  DeliveryAddressVO({
    required this.did,
    required this.name,
    required this.sex,
    required this.phone,
    required this.address,
  });

  factory DeliveryAddressVO.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressVO(
      did: (json['did'] as num).toInt(),
      name: json['name'] as String,
      sex: (json['sex'] as num).toInt(),
      phone: json['phone'] as String,
      address: json['address'] as String,
    );
  }
}
