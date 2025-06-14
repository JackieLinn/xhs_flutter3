class DeliveryAddressSaveRO {
  final String name;
  final int sex;
  final String phone;
  final String address;
  final int uid;

  DeliveryAddressSaveRO({
    required this.name,
    required this.sex,
    required this.phone,
    required this.address,
    required this.uid,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sex': sex,
      'phone': phone,
      'address': address,
      'uid': uid,
    };
  }
}
