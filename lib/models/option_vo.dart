class OptionVO {
  final int id;
  final String content;

  OptionVO({
    required this.id,
    required this.content,
  });

  factory OptionVO.fromJson(Map<String, dynamic> json) {
    return OptionVO(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
    };
  }
}
