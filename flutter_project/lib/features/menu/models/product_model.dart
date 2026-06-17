class ProductSideOption {
  final String id;
  final String name;
  final String nameAr;
  final String image;
  final double price;

  ProductSideOption({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.price,
  });

  factory ProductSideOption.fromMap(Map<String, dynamic> map) {
    return ProductSideOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'image': image,
      'price': price,
    };
  }
}

class ProductModel {
  final String id;
  final String title;
  final String titleAr;
  final String description;
  final String descriptionAr;
  final double price;
  final String categoryId;
  final String image;
  final bool isPopular;
  final bool isHerbal;
  final double rating;
  final List<String> spicyOptions;
  final List<ProductSideOption> sideOptions;
  final bool isDeleted;

  ProductModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.description,
    required this.descriptionAr,
    required this.price,
    required this.categoryId,
    required this.image,
    this.isPopular = false,
    this.isHerbal = false,
    this.rating = 5.0,
    required this.spicyOptions,
    required this.sideOptions,
    this.isDeleted = false,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      title: map['title'] ?? '',
      titleAr: map['titleAr'] ?? '',
      description: map['description'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      image: map['image'] ?? '',
      isPopular: map['isPopular'] as bool? ?? false,
      isHerbal: map['isHerbal'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      spicyOptions: List<String>.from(map['spicyOptions'] ?? []),
      sideOptions: (map['sideOptions'] as List? ?? [])
          .map((item) => ProductSideOption.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleAr': titleAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'price': price,
      'categoryId': categoryId,
      'image': image,
      'isPopular': isPopular,
      'isHerbal': isHerbal,
      'rating': rating,
      'spicyOptions': spicyOptions,
      'sideOptions': sideOptions.map((e) => e.toMap()).toList(),
      'isDeleted': isDeleted,
    };
  }
}
