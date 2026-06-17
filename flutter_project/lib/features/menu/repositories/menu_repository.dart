import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class MenuRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts();
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class StaticMenuRepositoryImpl implements MenuRepository {
  final List<CategoryModel> _categories = [
    CategoryModel(id: "grill", name: "Grill", nameAr: "مشاوي", icon: "Flame"),
    CategoryModel(id: "sides", name: "Sides", nameAr: "مقبلات", icon: "Utensils"),
    CategoryModel(id: "drinks", name: "Drinks", nameAr: "مشروبات", icon: "CupSoda"),
    CategoryModel(id: "salads", name: "Salads", nameAr: "سلطات", icon: "Leaf"),
    CategoryModel(id: "desserts", name: "Desserts", nameAr: "حلويات", icon: "Cake"),
  ];

  final List<ProductModel> _products = [
    ProductModel(
      id: "g1",
      title: "Classic Chicken Tikka",
      titleAr: "شيش طاووق كلاسيك",
      description: "Succulent boneless chicken chunks marinated in Greek yogurt and secret tandoori spices, slow-grilled over tandoori charcoal. Served with fresh mint chutney.",
      descriptionAr: "شيش طاووق دجاج مخلي من العظم متبل بالزبادي اليوناني وتوابل التندوري السرية، مشوي على الفحم الهادئ. يقدم مع صلصة النعناع الطازجة.",
      price: 8.50,
      categoryId: "grill",
      image: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&q=80&w=600",
      isPopular: true,
      rating: 4.9,
      spicyOptions: ["Mild", "Medium", "Hot"],
      sideOptions: [
        ProductSideOption(id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&q=80&w=150", price: 0.0),
        ProductSideOption(id: "fries", name: "French Fries", nameAr: "بطاطا مقلية", image: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&q=80&w=150", price: 0.50),
        ProductSideOption(id: "rice", name: "Basmati Rice", nameAr: "أرز بسمتي فاخر", image: "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=150", price: 0.80)
      ],
    ),
    ProductModel(
      id: "g2",
      title: "Malai Boti Special",
      titleAr: "شيش طاووق كريمي (مالاي)",
      description: "Mildly spiced chicken cubes prepared in a rich cashew nut and heavy cream marinade for a buttery melt-in-the-mouth heritage taste.",
      descriptionAr: "مكعبات شيش طاووق منكهة ببهارات خفيفة متبلة بصلصة الكاجو الفاخرة والقشطة الطازجة لتذوب في الفم بطعم غني وشهي.",
      price: 9.20,
      categoryId: "grill",
      image: "https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&q=80&w=600",
      rating: 4.8,
      spicyOptions: ["Mild", "Medium"],
      sideOptions: [
        ProductSideOption(id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&q=80&w=150", price: 0.0),
        ProductSideOption(id: "fries", name: "French Fries", nameAr: "بطاطا مقلية", image: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&q=80&w=150", price: 0.50)
      ],
    ),
    ProductModel(
      id: "g3",
      title: "Hariyali Green Grill",
      titleAr: "شيش طاووق هاريالي الأخضر",
      description: "Chicken breast pieces coated with a vibrant aromatic paste of fresh mint, cilantro, spinach, and fiery green chilies, charcoal-roasted.",
      descriptionAr: "قطع صدور الدجاج الشهية المغلفة بتتبيلة الأعشاب الخضراء الفواحة والنعناع والكزبرة والسبانخ مع لمسة من الفلفل الحار، مشوية على الفحم.",
      price: 8.75,
      categoryId: "grill",
      image: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=600",
      isHerbal: true,
      rating: 4.7,
      spicyOptions: ["Medium", "Hot"],
      sideOptions: [
        ProductSideOption(id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&q=80&w=150", price: 0.0),
        ProductSideOption(id: "rice", name: "Basmati Rice", nameAr: "أرز بسمتي فاخر", image: "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=150", price: 0.80)
      ],
    ),
    ProductModel(
      id: "s1",
      title: "Crinkle Cut Fries",
      titleAr: "بطاطا مقلية متموجة كرانشي",
      description: "Perfectly golden crispy crinkle cut fries seasoned with our signature tandoori spice salt blend.",
      descriptionAr: "بطاطا مقلية ذهبية متموجة ومقرمشة متبلة بملح بهارات التندوري الكلاسيكية الخاصة بنا.",
      price: 1.80,
      categoryId: "sides",
      image: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&q=80&w=600",
      rating: 4.5,
      spicyOptions: ["Standard"],
      sideOptions: [],
    )
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _categories;
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    return _products.where((p) => !p.isDeleted).toList();
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _products[idx] = ProductModel(
        id: id,
        title: _products[idx].title,
        titleAr: _products[idx].titleAr,
        description: _products[idx].description,
        descriptionAr: _products[idx].descriptionAr,
        price: _products[idx].price,
        categoryId: _products[idx].categoryId,
        image: _products[idx].image,
        isPopular: _products[idx].isPopular,
        isHerbal: _products[idx].isHerbal,
        rating: _products[idx].rating,
        spicyOptions: _products[idx].spicyOptions,
        sideOptions: _products[idx].sideOptions,
        isDeleted: true,
      );
    }
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return StaticMenuRepositoryImpl();
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(menuRepositoryProvider);
  return repo.getCategories();
});

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(menuRepositoryProvider);
  return repo.getProducts();
});

final categoryFilterProvider = StateProvider<String>((ref) => "grill");
final searchQueryProvider = StateProvider<String>((ref) => "");

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final activeCat = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return productsAsync.maybeWhen(
    data: (list) => list.where((p) {
      final matchesCategory = p.categoryId == activeCat;
      final matchesQuery = p.title.toLowerCase().contains(query) || p.titleAr.contains(query);
      return matchesCategory && (query.isEmpty ? true : matchesQuery);
    }).toList(),
    orElse: () => [],
  );
});
