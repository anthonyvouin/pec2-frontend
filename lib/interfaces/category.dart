class Category {
  final String id;
  final String name;
  final String? description;
  final String? pictureUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.pictureUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pictureUrl: json['pictureUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'pictureUrl': pictureUrl,
  };
}