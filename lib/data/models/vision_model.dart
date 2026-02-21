class VisionItem {
  final String id;
  final String vision;
  final String avoid;
  final String category;
  final List<String> tags;
  final String? imageUrl;

  VisionItem({
    required this.id,
    required this.vision,
    required this.avoid,
    this.category = "",
    this.tags = const [],
    this.imageUrl,
  });

  factory VisionItem.fromFirestore(String id, Map<String, dynamic> data) {
    return VisionItem(
      id: id,
      vision: data['vision'] as String? ?? "",
      avoid: data['avoid'] as String? ?? "",
      category: data['category'] as String? ?? "",
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      imageUrl: data['imageUrl'] as String?,
    );
  }

  factory VisionItem.fromJson(Map<String, dynamic> json) {
    return VisionItem(
      id: json['id'] as String? ?? "",
      vision: json['vision'] as String? ?? "",
      avoid: json['avoid'] as String? ?? "",
      category: json['category'] as String? ?? "",
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vision': vision,
      'avoid': avoid,
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
    };
  }
}
