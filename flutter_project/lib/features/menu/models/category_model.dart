class CategoryModel {
  final String id;
  final String name;
  final String nameAr;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.icon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      icon: map['icon'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'icon': icon,
    };
  }
}
