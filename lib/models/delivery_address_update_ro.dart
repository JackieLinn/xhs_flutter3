class DeliveryAddressUpdateRO {
  final int did;
  final String name;
  final int sex;
  final String phone;
  final String address;
  final int uid;

  DeliveryAddressUpdateRO({
    required this.did,
    required this.name,
    required this.sex,
    required this.phone,
    required this.address,
    required this.uid,
  });

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'name': name,
      'sex': sex,
      'phone': phone,
      'address': address,
      'uid': uid,
    };
  }
}
