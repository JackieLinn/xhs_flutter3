class PaymentRO {
  final int uid;
  final int oid;

  PaymentRO({required this.uid, required this.oid});

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'oid': oid,
  };
} 