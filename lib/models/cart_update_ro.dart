class CartUpdateRO {
  final int cid; // 购物车 ID
  final int type; // 操作类型：1=增加，0=减少

  CartUpdateRO({required this.cid, required this.type});

  Map<String, dynamic> toJson() {
    return {'cid': cid, 'type': type};
  }
}
