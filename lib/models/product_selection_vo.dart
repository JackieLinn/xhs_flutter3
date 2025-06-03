import 'option_vo.dart';

class ProductSelectionVO {
  final int id;
  final double price;
  final String image;
  /// categories: 列表中每个 Map 的 key 是分类名称 (String)，value 是该分类下的 OptionVO 列表
  final List<Map<String, List<OptionVO>>> categories;

  ProductSelectionVO({
    required this.id,
    required this.price,
    required this.image,
    required this.categories,
  });

  factory ProductSelectionVO.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final price = (json['price'] as num).toDouble();
    final image = json['image'] as String;

    final List<dynamic> rawCategories = json['categories'] as List<dynamic>;
    final List<Map<String, List<OptionVO>>> parsedCategories = [];

    for (var element in rawCategories) {
      if (element is Map<String, dynamic>) {
        final Map<String, List<OptionVO>> categoryMap = {};
        element.forEach((key, value) {
          if (value is List<dynamic>) {
            final List<OptionVO> options = value
                .map((optItem) => OptionVO.fromJson(optItem as Map<String, dynamic>))
                .toList();
            categoryMap[key] = options;
          }
        });
        parsedCategories.add(categoryMap);
      }
    }

    return ProductSelectionVO(
      id: id,
      price: price,
      image: image,
      categories: parsedCategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'image': image,
      'categories': categories.map((categoryMap) {
        final Map<String, dynamic> serialized = {};
        categoryMap.forEach((key, optionList) {
          serialized[key] = optionList.map((opt) => opt.toJson()).toList();
        });
        return serialized;
      }).toList(),
    };
  }
}
