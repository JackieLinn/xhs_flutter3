class ProductClassification {
  final int id;
  final String name;

  ProductClassification({required this.id, required this.name});

  factory ProductClassification.fromJson(Map<String, dynamic> json) {
    return ProductClassification(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
